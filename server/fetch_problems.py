#!/usr/bin/env python3
"""
每日赛题文件下载脚本
从 FormaLLM 竞赛 API 获取每日赛题并保存到文件
"""

import requests
import json
import os
import sys
from datetime import datetime, timezone, timedelta
import pytz

# API 配置
API_BASE_URL = os.getenv("FORMALLM_API_BASE", "http://121.43.230.124")
API_KEY = os.getenv("FORMALLM_API_KEY", "default_api_key")

# 文件保存目录
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
FILES_DIR = os.path.join(PROJECT_ROOT, "assets", "files")


def fetch_daily_problems(date=None, track="all"):
    """
    获取每日赛题
    
    Args:
        date: 日期 (YYYY-MM-DD 格式)，默认为今天
        track: 赛道 ("lean", "litex", 或 "all")
    
    Returns:
        dict: {
            "date": "2025-11-06",
            "lean": [...],
            "litex": [...]
        }
    """
    if date is None:
        # 使用北京时间（UTC+8）
        tz_beijing = timezone(timedelta(hours=8))
        date = datetime.now(tz_beijing).strftime('%Y-%m-%d')
    
    # 这里需要根据您的实际 API 端点调整
    # 假设 API 格式为: /problems/daily?date=YYYY-MM-DD&track=lean
    
    result = {
        "date": date,
        "lean": [],
        "litex": []
    }
    
    if track in ["all", "lean"]:
        url = f"{API_BASE_URL}/problems/daily"
        headers = {"X-API-Key": API_KEY}
        params = {"date": date, "track": "lean"}
        
        print(f"📡 获取 Lean 赛题 (日期: {date})...")
        try:
            response = requests.get(url, headers=headers, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if "error" not in data and isinstance(data, list):
                result["lean"] = data
                print(f"✅ 成功获取 Lean 赛题: {len(data)} 题")
            else:
                print(f"⚠️  Lean 赛题暂无数据")
        except requests.exceptions.RequestException as e:
            print(f"❌ Lean 赛题获取失败: {e}")
    
    if track in ["all", "litex"]:
        url = f"{API_BASE_URL}/problems/daily"
        headers = {"X-API-Key": API_KEY}
        params = {"date": date, "track": "litex"}
        
        print(f"📡 获取 Litex 赛题 (日期: {date})...")
        try:
            response = requests.get(url, headers=headers, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if "error" not in data and isinstance(data, list):
                result["litex"] = data
                print(f"✅ 成功获取 Litex 赛题: {len(data)} 题")
            else:
                print(f"⚠️  Litex 赛题暂无数据")
        except requests.exceptions.RequestException as e:
            print(f"❌ Litex 赛题获取失败: {e}")
    
    return result


def save_problems_to_files(problems_data):
    """
    将赛题数据保存为 JSONL 文件（直接复制已有文件）
    
    Args:
        problems_data: 包含日期和赛题的字典，支持从预置文件复制
    
    Returns:
        list: 保存的文件路径列表
    """
    date = problems_data["date"]
    date_str = date.replace("-", "")  # 20251106
    saved_files = []
    
    # 确保目录存在
    os.makedirs(FILES_DIR, exist_ok=True)
    
    # 保存 Lean 赛题
    if problems_data.get("lean_file"):
        # 如果提供了源文件路径，直接复制
        source_file = problems_data["lean_file"]
        filename = f"lean_{date_str[4:]}.jsonl"  # lean_1106.jsonl
        filepath = os.path.join(FILES_DIR, filename)
        
        import shutil
        shutil.copy2(source_file, filepath)
        print(f"💾 Lean 赛题已复制: {source_file} -> {filename}")
        saved_files.append(filepath)
    elif problems_data["lean"]:
        # API 方式保存
        filename = f"lean_{date_str[4:]}.jsonl"
        filepath = os.path.join(FILES_DIR, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            for problem in problems_data["lean"]:
                f.write(json.dumps(problem, ensure_ascii=False) + '\n')
        
        print(f"💾 Lean 赛题已保存: {filename} ({len(problems_data['lean'])} 题)")
        saved_files.append(filepath)
    
    # 保存 Litex 赛题
    if problems_data.get("litex_file"):
        # 如果提供了源文件路径，直接复制
        source_file = problems_data["litex_file"]
        filename = f"litex_{date_str[4:]}.jsonl"
        filepath = os.path.join(FILES_DIR, filename)
        
        import shutil
        shutil.copy2(source_file, filepath)
        print(f"💾 Litex 赛题已复制: {source_file} -> {filename}")
        saved_files.append(filepath)
    elif problems_data["litex"]:
        # API 方式保存
        filename = f"litex_{date_str[4:]}.jsonl"
        filepath = os.path.join(FILES_DIR, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            for problem in problems_data["litex"]:
                f.write(json.dumps(problem, ensure_ascii=False) + '\n')
        
        print(f"💾 Litex 赛题已保存: {filename} ({len(problems_data['litex'])} 题)")
        saved_files.append(filepath)
    
    return saved_files


def update_downloads_json(problems_data, saved_files):
    """
    更新 downloads.json 配置文件
    
    Args:
        problems_data: 赛题数据
        saved_files: 保存的文件路径列表
    """
    downloads_json_path = os.path.join(PROJECT_ROOT, "assets", "data", "downloads.json")
    
    if not os.path.exists(downloads_json_path):
        print("⚠️  downloads.json 不存在，跳过更新")
        return
    
    # 读取现有配置
    with open(downloads_json_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    # 准备新的赛题条目
    date = problems_data["date"]
    date_obj = datetime.strptime(date, '%Y-%m-%d')
    
    # 如果当前时间在北京时间23:00之后，timestamp 写入明天的日期
    # 这样前端在23:00后就能匹配到"明天"的赛题
    now_bj = datetime.now(pytz.timezone('Asia/Shanghai'))
    if now_bj.hour >= 23:
        # 时间戳使用明天的日期
        display_date = date_obj + timedelta(days=1)
        timestamp = display_date.strftime('%Y-%m-%d %H:%M:%S')
    else:
        timestamp = date_obj.strftime('%Y-%m-%d %H:%M:%S')
    
    items = []
    for filepath in saved_files:
        filename = os.path.basename(filepath)
        
        # 计算 MD5
        import hashlib
        md5_hash = hashlib.md5()
        with open(filepath, 'rb') as f:
            md5_hash.update(f.read())
        md5 = md5_hash.hexdigest()
        
        # 确定赛道名称
        if filename.startswith("lean"):
            name = f"Lean 赛题 ({date_obj.strftime('%m月%d日')})"
        elif filename.startswith("litex"):
            name = f"Litex 赛题 ({date_obj.strftime('%m月%d日')})"
        else:
            name = filename
        
        items.append({
            "name": name,
            "md5": md5,
            "url": "https://www.xir.cn/competitions/1143",
            "local": f"assets/files/{filename}",
            "available": True
        })
    
    # 构建新的数据集条目
    new_dataset = {
        "timestamp": timestamp,
        "title": f"{date_obj.month}月{date_obj.day}日赛题",
        "note": "报名后可下载数据",
        "items": items
    }
    
    # 检查是否已存在相同日期的赛题
    existing_index = None
    for i, dataset in enumerate(config["datasets"]):
        if dataset.get("timestamp", "").startswith(date):
            existing_index = i
            break
    
    # 更新或插入新条目
    if existing_index is not None:
        config["datasets"][existing_index] = new_dataset
        print(f"🔄 更新已存在的赛题条目: {date}")
    else:
        config["datasets"].insert(0, new_dataset)
        print(f"➕ 添加新的赛题条目: {date}")
    
    # 更新 lastUpdated
    tz_beijing = timezone(timedelta(hours=8))
    config["lastUpdated"] = datetime.now(tz_beijing).isoformat()
    
    # 保存配置
    with open(downloads_json_path, 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    
    print(f"✅ downloads.json 已更新")


def main():
    """主函数"""
    print("=" * 60)
    print("📝 FormaLLM 每日赛题下载")
    print("=" * 60)
    print()
    
    # 获取命令行参数
    if len(sys.argv) > 1:
        global API_KEY
        API_KEY = sys.argv[1]
        print(f"🔑 使用自定义 API Key")
    
    date = sys.argv[2] if len(sys.argv) > 2 else None
    track = sys.argv[3] if len(sys.argv) > 3 else "all"
    
    print()
    
    # 1. 获取赛题数据
    problems_data = fetch_daily_problems(date, track)
    
    if not problems_data["lean"] and not problems_data["litex"]:
        print()
        print("⚠️  今日暂无赛题数据")
        return
    
    # 2. 保存为 JSONL 文件
    print()
    saved_files = save_problems_to_files(problems_data)
    
    if not saved_files:
        print("⚠️  没有保存任何文件")
        return
    
    # 3. 更新 downloads.json
    print()
    update_downloads_json(problems_data, saved_files)
    
    print()
    print("=" * 60)
    print("✅ 赛题下载完成！")
    print(f"📁 保存文件数: {len(saved_files)}")
    print("=" * 60)


if __name__ == "__main__":
    main()

