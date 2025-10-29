#!/usr/bin/env python3
"""
Lean 示例代码
演示如何使用 Lean 进行形式化数学证明
"""

import json
import os

def lean_example():
    """Lean 定理证明示例"""
    # 示例：证明 2 + 2 = 4
    lean_code = """
    theorem two_plus_two : 2 + 2 = 4 := by norm_num
    """
    
    print("Lean 示例代码:")
    print(lean_code)
    
    # 保存到文件
    with open("lean_example.lean", "w", encoding="utf-8") as f:
        f.write(lean_code)
    
    print("代码已保存到 lean_example.lean")

def process_dataset():
    """处理数据集示例"""
    dataset_path = "practice-dataset.jsonl"
    
    if os.path.exists(dataset_path):
        with open(dataset_path, "r", encoding="utf-8") as f:
            for line in f:
                data = json.loads(line.strip())
                print(f"处理题目 {data['id']}: {data['nl_problem'][:50]}...")
    else:
        print("数据集文件不存在")

if __name__ == "__main__":
    lean_example()
    process_dataset()
