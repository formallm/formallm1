#!/bin/bash
#
# 手动触发数据更新（用于测试）
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/update-data.sh"

echo "=== 手动触发数据更新 ==="
echo ""
echo "脚本路径: $UPDATE_SCRIPT"
echo ""

# 检查脚本是否存在
if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo "ERROR: 更新脚本不存在: $UPDATE_SCRIPT"
    exit 1
fi

# 确保脚本可执行
chmod +x "$UPDATE_SCRIPT"

# 执行更新
echo "开始执行更新..."
echo ""

bash "$UPDATE_SCRIPT"

echo ""
echo "=== 更新完成 ==="

