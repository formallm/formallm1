#!/usr/bin/env python3
"""
排行榜数据获取脚本
从 ForMaLLM 竞赛 API 获取排行榜数据并保存为 JSON
"""

import requests
import json
import os
import sys
from datetime import datetime, timezone, timedelta

# API 配置
API_BASE_URL = os.getenv("FORMALLM_API_BASE", "http://121.43.230.124")
API_KEY = os.getenv("FORMALLM_API_KEY", "default_api_key")  # 请替换为您的真实 API Key

# 比赛阶段（preliminary 或 practice）
STAGE = os.getenv("FORMALLM_STAGE", "preliminary")

# 输出文件路径（相对于仓库根目录）
OUTPUT_FILE = "assets/data/leaderboard.json"


def fetch_daily_ranking(stage=STAGE, date=None):
    """
    获取每日排行榜
    
    Args:
        stage: 比赛阶段
        date: 日期 (YYYY-MM-DD 格式)，默认为今天
    
    Returns:
        dict: API 响应数据
    """
    if date is None:
        # 使用北京时间（UTC+8）
        tz_beijing = timezone(timedelta(hours=8))
        date = datetime.now(tz_beijing).strftime('%Y-%m-%d')
    
    url = f"{API_BASE_URL}/ranking_list/daily"
    headers = {"X-API-Key": API_KEY}
    params = {"stage": stage, "dt": date}
    
    print(f"📡 获取每日排行榜 (日期: {date}, 阶段: {stage})...")
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        if "error" in data:
            print(f"❌ API 返回错误: {data['error']}")
            return None
        
        print(f"✅ 成功获取每日排行榜")
        return data
    
    except requests.exceptions.RequestException as e:
        print(f"❌ 请求失败: {e}")
        return None


def fetch_overall_ranking(stage=STAGE):
    """
    获取总排行榜
    
    Args:
        stage: 比赛阶段
    
    Returns:
        dict: API 响应数据
    """
    url = f"{API_BASE_URL}/ranking_list/overall"
    headers = {"X-API-Key": API_KEY}
    params = {"stage": stage}
    
    print(f"📡 获取总排行榜 (阶段: {stage})...")
    
    try:
        response = requests.get(url, headers=headers, params=params, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        if "error" in data:
            print(f"❌ API 返回错误: {data['error']}")
            return None
        
        print(f"✅ 成功获取总排行榜")
        return data
    
    except requests.exceptions.RequestException as e:
        print(f"❌ 请求失败: {e}")
        return None


def transform_ranking_data(api_data):
    """
    将 API 返回的数据转换为前端需要的格式
    
    Args:
        api_data: API 返回的原始数据
    
    Returns:
        list: 转换后的排行榜条目
    """
    if not api_data:
        return []
    
    entries = []
    for item in api_data:
        entry = {
            "rank": item.get("ranking", 0),
            "teamName": item.get("team_name", "Unknown"),
            "teamId": item.get("team_id", ""),
            "score": float(item.get("score", 0)),
            "members": "",  # API 中没有成员信息，可以从其他来源获取
            "submitTime": "",  # 根据需要添加
            "submissionCount": 0  # 根据需要添加
        }
        entries.append(entry)
    
    return entries


def merge_leaderboard_data(daily_data, overall_data):
    """
    合并每日和总榜数据，生成前端所需的完整数据结构
    
    Args:
        daily_data: 每日排行榜的 API 响应
        overall_data: 总排行榜的 API 响应
    
    Returns:
        dict: 前端需要的完整数据结构
    """
    # 从 daily_data 中提取第一个日期的数据
    date_key = None
    lean_daily = []
    litex_daily = []
    
    if daily_data and isinstance(daily_data, dict):
        # 获取第一个日期
        for key in daily_data.keys():
            if key != "stage":
                date_key = key
                break
        
        if date_key:
            day_data = daily_data[date_key]
            lean_daily = transform_ranking_data(day_data.get("lean_ranking", []))
            litex_daily = transform_ranking_data(day_data.get("litex_ranking", []))
    
    # 从 overall_data 中提取总榜数据
    lean_overall = []
    litex_overall = []
    
    if overall_data and isinstance(overall_data, dict):
        lean_overall = transform_ranking_data(overall_data.get("lean_ranking", []))
        litex_overall = transform_ranking_data(overall_data.get("litex_ranking", []))
    
    # 构建最终数据结构
    tz_beijing = timezone(timedelta(hours=8))
    now = datetime.now(tz_beijing)
    
    result = {
        "lastUpdated": now.isoformat(),
        "stage": daily_data.get("stage", STAGE) if daily_data else STAGE,
        "litex": {
            "daily": litex_daily,
            "overall": litex_overall
        },
        "lean": {
            "daily": lean_daily,
            "overall": lean_overall
        }
    }
    
    return result


def save_json(data, filepath):
    """
    保存 JSON 数据到文件
    
    Args:
        data: 要保存的数据
        filepath: 文件路径
    """
    # 确保目录存在
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    # 保存 JSON（格式化输出，便于查看和 Git diff）
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"💾 数据已保存到: {filepath}")


def main():
    """主函数"""
    print("=" * 60)
    print("🏆 ForMaLLM 竞赛排行榜数据获取")
    print("=" * 60)
    print()
    
    # 获取命令行参数（可选的 API Key 和 Stage）
    if len(sys.argv) > 1:
        global API_KEY
        API_KEY = sys.argv[1]
        print(f"🔑 使用自定义 API Key")
    
    if len(sys.argv) > 2:
        global STAGE
        STAGE = sys.argv[2]
        print(f"📋 使用比赛阶段: {STAGE}")
    
    print()
    
    # 1. 获取每日排行榜
    daily_data = fetch_daily_ranking(STAGE)
    
    # 2. 获取总排行榜
    overall_data = fetch_overall_ranking(STAGE)
    
    # 3. 检查是否至少有一个成功
    if not daily_data and not overall_data:
        print()
        print("❌ 无法获取任何排行榜数据，退出")
        sys.exit(1)
    
    # 4. 合并数据
    print()
    print("🔄 合并数据...")
    merged_data = merge_leaderboard_data(daily_data, overall_data)
    
    # 5. 保存到文件
    print()
    save_json(merged_data, OUTPUT_FILE)
    
    # 6. 显示统计信息
    print()
    print("=" * 60)
    print("📊 数据统计:")
    print(f"  Litex 每日: {len(merged_data['litex']['daily'])} 队")
    print(f"  Litex 总榜: {len(merged_data['litex']['overall'])} 队")
    print(f"  Lean 每日: {len(merged_data['lean']['daily'])} 队")
    print(f"  Lean 总榜: {len(merged_data['lean']['overall'])} 队")
    print(f"  比赛阶段: {merged_data['stage']}")
    print(f"  更新时间: {merged_data['lastUpdated']}")
    print("=" * 60)
    print()
    print("✅ 完成！")


if __name__ == "__main__":
    main()

