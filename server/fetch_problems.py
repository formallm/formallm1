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
    优先从本地文件系统读取，如果不存在则从远程 API 获取
    
    Args:
        date: 日期 (YYYY-MM-DD 格式)，默认为今天
        track: 赛道 ("lean", "litex", 或 "all")
    
    Returns:
        dict: {
            "date": "2025-11-06",
            "lean": [...],
            "litex": [...],
            "lean_file": "/path/to/lean_1106.jsonl",  # 如果从本地文件读取
            "litex_file": "/path/to/litex_1106.jsonl"  # 如果从本地文件读取
        }
    """
    if date is None:
        # 使用北京时间（UTC+8）
        tz_beijing = timezone(timedelta(hours=8))
        now_bj = datetime.now(tz_beijing)
        # 如果当前时间在 23:00 之后，获取第二天的赛题
        if now_bj.hour >= 23:
            date = (now_bj + timedelta(days=1)).strftime('%Y-%m-%d')
            print(f"🕐 当前时间 {now_bj.strftime('%H:%M:%S')}，获取第二天赛题: {date}")
        else:
            date = now_bj.strftime('%Y-%m-%d')
            print(f"🕐 当前时间 {now_bj.strftime('%H:%M:%S')}，获取当天赛题: {date}")
    
    result = {
        "date": date,
        "lean": [],
        "litex": []
    }
    
    # 计算文件名格式：MMDD (例如：1109 表示 11月09日)
    date_obj = datetime.strptime(date, '%Y-%m-%d')
    date_str = date_obj.strftime('%m%d')  # MMDD 格式
    
    # 优先从本地文件系统读取
    if track in ["all", "lean"]:
        lean_filename = f"lean_{date_str}.jsonl"
        lean_filepath = os.path.join(FILES_DIR, lean_filename)
        
        if os.path.exists(lean_filepath):
            print(f"📂 从本地文件读取 Lean 赛题: {lean_filename}")
            result["lean_file"] = lean_filepath
            # 读取文件内容以验证文件有效性
            try:
                with open(lean_filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    if lines:
                        # 尝试解析第一行验证格式
                        json.loads(lines[0].strip())
                        print(f"✅ 本地 Lean 赛题文件有效: {len(lines)} 题")
                    else:
                        print(f"⚠️  本地 Lean 赛题文件为空")
            except Exception as e:
                print(f"⚠️  本地 Lean 赛题文件格式错误: {e}，将尝试从 API 获取")
                result.pop("lean_file", None)
        else:
            print(f"📡 本地文件不存在，尝试从 API 获取 Lean 赛题 (日期: {date})...")
            url = f"{API_BASE_URL}/problems/daily"
            headers = {"X-API-Key": API_KEY}
            params = {"date": date, "track": "lean"}
            
            try:
                response = requests.get(url, headers=headers, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()
                
                if "error" not in data and isinstance(data, list):
                    result["lean"] = data
                    print(f"✅ 成功从 API 获取 Lean 赛题: {len(data)} 题")
                else:
                    print(f"⚠️  Lean 赛题暂无数据")
            except requests.exceptions.RequestException as e:
                print(f"❌ Lean 赛题获取失败: {e}")
    
    if track in ["all", "litex"]:
        litex_filename = f"litex_{date_str}.jsonl"
        litex_filepath = os.path.join(FILES_DIR, litex_filename)
        
        if os.path.exists(litex_filepath):
            print(f"📂 从本地文件读取 Litex 赛题: {litex_filename}")
            result["litex_file"] = litex_filepath
            # 读取文件内容以验证文件有效性
            try:
                with open(litex_filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    if lines:
                        # 尝试解析第一行验证格式
                        json.loads(lines[0].strip())
                        print(f"✅ 本地 Litex 赛题文件有效: {len(lines)} 题")
                    else:
                        print(f"⚠️  本地 Litex 赛题文件为空")
            except Exception as e:
                print(f"⚠️  本地 Litex 赛题文件格式错误: {e}，将尝试从 API 获取")
                result.pop("litex_file", None)
        else:
            print(f"📡 本地文件不存在，尝试从 API 获取 Litex 赛题 (日期: {date})...")
            url = f"{API_BASE_URL}/problems/daily"
            headers = {"X-API-Key": API_KEY}
            params = {"date": date, "track": "litex"}
            
            try:
                response = requests.get(url, headers=headers, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()
                
                if "error" not in data and isinstance(data, list):
                    result["litex"] = data
                    print(f"✅ 成功从 API 获取 Litex 赛题: {len(data)} 题")
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
        # 如果提供了源文件路径，直接复制（如果源文件和目标文件不同）
        source_file = problems_data["lean_file"]
        filename = f"lean_{date_str[4:]}.jsonl"  # lean_1106.jsonl
        filepath = os.path.join(FILES_DIR, filename)
        
        # 标准化路径以便比较
        source_file_abs = os.path.abspath(source_file)
        filepath_abs = os.path.abspath(filepath)
        
        if source_file_abs != filepath_abs:
            import shutil
            shutil.copy2(source_file, filepath)
            print(f"💾 Lean 赛题已复制: {os.path.basename(source_file)} -> {filename}")
        else:
            print(f"💾 Lean 赛题文件已在目标位置: {filename}")
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
        # 如果提供了源文件路径，直接复制（如果源文件和目标文件不同）
        source_file = problems_data["litex_file"]
        filename = f"litex_{date_str[4:]}.jsonl"
        filepath = os.path.join(FILES_DIR, filename)
        
        # 标准化路径以便比较
        source_file_abs = os.path.abspath(source_file)
        filepath_abs = os.path.abspath(filepath)
        
        if source_file_abs != filepath_abs:
            import shutil
            shutil.copy2(source_file, filepath)
            print(f"💾 Litex 赛题已复制: {os.path.basename(source_file)} -> {filename}")
        else:
            print(f"💾 Litex 赛题文件已在目标位置: {filename}")
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
    # problems_data["date"] 已经是正确的日期（23:00后会自动是第二天的日期）
    date = problems_data["date"]
    date_obj = datetime.strptime(date, '%Y-%m-%d')
    
    # 获取当前北京时间用于时间戳
    now_bj = datetime.now(pytz.timezone('Asia/Shanghai'))
    # 直接使用 problems_data["date"] 作为显示日期（已经是正确的日期）
    timestamp = f"{date_obj.strftime('%Y-%m-%d')} {now_bj.strftime('%H:%M:%S')}"
    title_date = date_obj
    
    print(f"📅 赛题日期: {date}")
    print(f"🕐 当前时间: {now_bj.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📝 生成 timestamp: {timestamp}")
    print(f"📋 生成 title: {title_date.month}月{title_date.day}日赛题")
    
    items = []
    for filepath in saved_files:
        filename = os.path.basename(filepath)
        
        # 计算 MD5
        import hashlib
        md5_hash = hashlib.md5()
        with open(filepath, 'rb') as f:
            md5_hash.update(f.read())
        md5 = md5_hash.hexdigest()
        
        # 确定赛道名称（使用与 title 一致的日期）
        if filename.startswith("lean"):
            name = f"Lean 赛题 ({title_date.strftime('%m月%d日')})"
        elif filename.startswith("litex"):
            name = f"Litex 赛题 ({title_date.strftime('%m月%d日')})"
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
        "title": f"{title_date.month}月{title_date.day}日赛题",
        "note": "报名后可下载数据",
        "items": items
    }
    
    # 检查是否已存在相同日期的赛题
    # 使用 timestamp 的日期部分来匹配（因为23:00后 timestamp 可能是明天的日期）
    timestamp_date = timestamp[:10]  # 提取 YYYY-MM-DD 部分
    existing_index = None
    for i, dataset in enumerate(config["datasets"]):
        dataset_timestamp = dataset.get("timestamp", "")
        dataset_date = dataset_timestamp[:10] if dataset_timestamp else ""
        if dataset_date == timestamp_date:
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
    
    return config  # 返回更新后的配置，用于更新 HTML


def convert_title_to_english(chinese_title):
    """
    将中文标题转换为英文标题
    例如: "11月09日赛题" -> "Nov 9 Problems"
    """
    import re
    # 匹配格式：XX月XX日赛题
    match = re.match(r'(\d+)月(\d+)日赛题', chinese_title)
    if match:
        month = int(match.group(1))
        day = int(match.group(2))
        month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        if 1 <= month <= 12:
            return f"{month_names[month-1]} {day} Problems"
    # 如果无法匹配，返回原标题
    return chinese_title


def update_html_embedded_json(config):
    """
    更新 HTML 文件中的内嵌 JSON 数据
    
    Args:
        config: 更新后的 downloads.json 配置数据
    """
    import re
    
    html_files = [
        (os.path.join(PROJECT_ROOT, "cn", "downloads.html"), "zh"),
        (os.path.join(PROJECT_ROOT, "en", "downloads.html"), "en")
    ]
    
    print(f"📂 项目根目录: {PROJECT_ROOT}")
    print(f"📂 HTML 文件目录: {os.path.join(PROJECT_ROOT, 'cn')} 和 {os.path.join(PROJECT_ROOT, 'en')}")
    print(f"📂 downloads.json 路径: {os.path.join(PROJECT_ROOT, 'assets', 'data', 'downloads.json')}")
    print(f"📂 文件保存目录: {os.path.join(PROJECT_ROOT, 'assets', 'files')}")
    
    for html_path, lang in html_files:
        print(f"\n🔍 检查 HTML 文件: {html_path}")
        if not os.path.exists(html_path):
            print(f"⚠️  HTML 文件不存在: {html_path}")
            print(f"   当前工作目录: {os.getcwd()}")
            continue
        print(f"✅ HTML 文件存在: {html_path}")
        
        try:
            # 根据语言版本创建配置副本并转换标题
            config_copy = json.loads(json.dumps(config))  # 深拷贝
            
            # 调整路径：HTML 文件在子目录中，需要添加 ../ 前缀
            # downloads.json 中的路径是 assets/files/...（相对于项目根）
            # HTML 文件在 cn/ 或 en/ 目录中，需要使用 ../assets/files/...
            # 部署路径示例：
            #   HTML: /var/www/formallm1/cn/downloads.html
            #   downloads.json: /var/www/formallm1/assets/data/downloads.json
            #   文件: /var/www/formallm1/assets/files/...
            #   从 cn/ 访问 assets/files/ 需要 ../assets/files/
            path_adjusted_count = 0
            for dataset in config_copy.get("datasets", []):
                for item in dataset.get("items", []):
                    if "local" in item and item["local"]:
                        # 如果路径以 assets/ 开头且没有 ../ 前缀，则添加
                        if item["local"].startswith("assets/") and not item["local"].startswith("../"):
                            old_path = item["local"]
                            item["local"] = "../" + item["local"]
                            path_adjusted_count += 1
                            if path_adjusted_count <= 2:  # 只打印前2个，避免日志过多
                                print(f"   🔄 路径调整: {old_path} -> {item['local']}")
            
            # 同样处理 examples 中的路径
            for example in config_copy.get("examples", []):
                for item in example.get("items", []):
                    if "local" in item and item["local"]:
                        if item["local"].startswith("assets/") and not item["local"].startswith("../"):
                            old_path = item["local"]
                            item["local"] = "../" + item["local"]
                            path_adjusted_count += 1
            
            if path_adjusted_count > 0:
                print(f"   ✅ 已调整 {path_adjusted_count} 个文件路径（添加 ../ 前缀）")
            
            # 如果是英文版本，转换标题
            if lang == "en":
                for dataset in config_copy.get("datasets", []):
                    if "title" in dataset:
                        dataset["title"] = convert_title_to_english(dataset["title"])
                # 转换 items 中的 name（如果有中文格式）
                for dataset in config_copy.get("datasets", []):
                    for item in dataset.get("items", []):
                        if "name" in item:
                            # 匹配格式：Lean 赛题 (XX月XX日) 或 Litex 赛题 (XX月XX日)
                            match = re.match(r'(Lean|Litex) 赛题 \((\d+)月(\d+)日\)', item["name"])
                            if match:
                                track = match.group(1)
                                month = int(match.group(2))
                                day = int(match.group(3))
                                month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
                                if 1 <= month <= 12:
                                    item["name"] = f"{month_names[month-1]} {day} {track} Problems"
            
            # 准备 JSON 字符串（格式化，2 空格缩进）
            json_str = json.dumps(config_copy, ensure_ascii=False, indent=2)
            
            # 读取 HTML 文件
            with open(html_path, 'r', encoding='utf-8') as f:
                html_content = f.read()
            
            # 使用更可靠的方法：找到 script 标签的开始和结束位置
            # 先找到 <script id="downloads-data"> 的开始位置
            script_start_pattern = r'<script\s+id=["\']downloads-data["\'][^>]*>'
            script_start_match = re.search(script_start_pattern, html_content)
            
            if not script_start_match:
                print(f"⚠️  HTML 文件未找到 downloads-data script 标签: {os.path.basename(html_path)}")
                continue
            
            print(f"🔍 找到 script 标签: {os.path.basename(html_path)} ({lang})")
            script_start = script_start_match.end()  # script 标签结束位置（> 之后）
            
            # 从 script 标签后开始，找到对应的 </script> 结束位置
            # 需要找到与 <script> 匹配的 </script>，而不是其他 script 标签的
            script_end_pattern = r'</script>'
            script_end_match = re.search(script_end_pattern, html_content[script_start:])
            
            if not script_end_match:
                print(f"⚠️  HTML 文件未找到对应的 </script> 标签: {os.path.basename(html_path)}")
                continue
            
            print(f"🔍 找到 </script> 标签: {os.path.basename(html_path)} ({lang})")
            
            script_end = script_start + script_end_match.start()  # </script> 开始位置
            
            # 提取 JSON 内容（去除首尾空白）
            old_json_content = html_content[script_start:script_end].strip()
            
            # 比较 JSON 内容（解析后比较，避免格式差异）
            try:
                old_json_data = json.loads(old_json_content)
                new_json_data = json.loads(json_str)
                # 如果 JSON 内容相同，则跳过更新
                if old_json_data == new_json_data:
                    print(f"ℹ️  HTML 文件 JSON 内容未变化: {os.path.basename(html_path)} ({lang})")
                    continue
                else:
                    print(f"🔄 JSON 内容有变化，准备更新: {os.path.basename(html_path)} ({lang})")
            except json.JSONDecodeError as e:
                print(f"⚠️  解析旧 JSON 内容失败: {e}，将强制更新")
                # 如果解析失败，继续更新
            
            # 获取缩进信息（从 script 标签前的行获取）
            script_tag_line_start = html_content.rfind('\n', 0, script_start_match.start()) + 1
            indent_str = html_content[script_tag_line_start:script_start_match.start()]
            # 只保留空格/制表符
            indent_str = ''.join(c for c in indent_str if c in ' \t')
            
            # 构建新的 HTML 内容
            new_html = (
                html_content[:script_start] + 
                '\n' + json_str + '\n' + indent_str + 
                html_content[script_end:]
            )
            
            # 写回文件
            with open(html_path, 'w', encoding='utf-8') as f:
                f.write(new_html)
            print(f"✅ HTML 内嵌数据已更新: {os.path.basename(html_path)} ({lang})")
            print(f"   📍 文件路径: {html_path}")
            print(f"   📊 数据集数量: {len(config_copy.get('datasets', []))}")
            if config_copy.get('datasets'):
                latest = config_copy['datasets'][0]
                print(f"   📅 最新赛题日期: {latest.get('timestamp', 'N/A')[:10]}")
                print(f"   📝 最新赛题标题: {latest.get('title', 'N/A')}")
                
        except Exception as e:
            print(f"❌ 更新 HTML 文件失败 {os.path.basename(html_path)}: {e}")
            import traceback
            traceback.print_exc()


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
    
    # 检查是否有赛题数据（可能是从本地文件或 API 获取）
    has_lean = problems_data.get("lean_file") or problems_data.get("lean")
    has_litex = problems_data.get("litex_file") or problems_data.get("litex")
    
    if not has_lean and not has_litex:
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
    config = update_downloads_json(problems_data, saved_files)
    
    # 4. 更新 HTML 文件中的内嵌 JSON
    if config:
        print()
        print("=" * 60)
        print("📄 开始更新 HTML 文件中的内嵌 JSON...")
        print("=" * 60)
        update_html_embedded_json(config)
    else:
        print()
        print("⚠️  配置数据为空，跳过 HTML 更新")
    
    print()
    print("=" * 60)
    print("✅ 赛题下载完成！")
    print(f"📁 保存文件数: {len(saved_files)}")
    print("=" * 60)


if __name__ == "__main__":
    main()

