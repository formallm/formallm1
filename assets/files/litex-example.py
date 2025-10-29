#!/usr/bin/env python3
"""
Litex 示例代码
演示如何使用 Litex 进行形式化数学证明
"""

import json
import os

def litex_example():
    """Litex 定理证明示例"""
    # 示例：证明自然数的加法结合律
    litex_code = """
    import Nat

    theorem add_assoc (a b c : Nat) : (a + b) + c = a + (b + c) := by
      induction c with
      | zero => simp
      | succ c ih => simp [add_succ, ih]
    """
    
    print("Litex 示例代码:")
    print(litex_code)
    
    # 保存到文件
    with open("litex_example.ltx", "w", encoding="utf-8") as f:
        f.write(litex_code)
    
    print("代码已保存到 litex_example.ltx")

def generate_submission():
    """生成提交格式示例"""
    submission_data = {
        "id": "100439",
        "nl_problem": "21) For how many natural numbers $n$, both $n$ and $(n-6)^{2}+1$ are prime?",
        "formal_type": "Litex",
        "header": "import Nat\nimport Prime",
        "formal_statement": "claim count_primes : ∃ n : Nat, Prime n ∧ Prime ((n-6)^2 + 1)",
        "formal_code": "proof by contradiction\n  assume h : ¬∃ n : Nat, Prime n ∧ Prime ((n-6)^2 + 1)\n  -- 证明逻辑省略\nqed"
    }
    
    with open("submission_example.jsonl", "w", encoding="utf-8") as f:
        f.write(json.dumps(submission_data, ensure_ascii=False) + "\n")
    
    print("提交示例已保存到 submission_example.jsonl")

if __name__ == "__main__":
    litex_example()
    generate_submission()
