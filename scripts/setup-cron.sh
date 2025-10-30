#!/bin/bash
#
# 在云服务器上配置定时任务
#

set -e

echo "=== 配置自动更新定时任务 ==="

# 脚本路径
SCRIPT_DIR="/var/www/formsci/scripts"
UPDATE_SCRIPT="$SCRIPT_DIR/update-data.sh"

# 确保脚本可执行
chmod +x "$UPDATE_SCRIPT"

echo "✓ 脚本权限已设置"

# 创建日志目录
sudo mkdir -p /var/log/formsci-update
sudo chown $USER:$USER /var/log/formsci-update

echo "✓ 日志目录已创建"

# 备份现有crontab
crontab -l > /tmp/crontab.backup 2>/dev/null || true

echo "✓ 已备份现有crontab"

# 检查是否已存在定时任务
if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
    echo "⚠ 定时任务已存在，跳过添加"
else
    # 添加定时任务（每天凌晨1点和下午1点执行）
    (crontab -l 2>/dev/null || true; echo "# 自动更新排行榜和赛题数据") | crontab -
    (crontab -l 2>/dev/null; echo "0 1,13 * * * $UPDATE_SCRIPT >> /var/log/formsci-update/cron.log 2>&1") | crontab -
    
    echo "✓ 定时任务已添加"
fi

# 显示当前crontab
echo ""
echo "当前的crontab配置："
echo "-------------------"
crontab -l
echo "-------------------"

echo ""
echo "=== 配置完成 ==="
echo ""
echo "定时任务将在以下时间执行："
echo "  - 每天 01:00 (凌晨1点)"
echo "  - 每天 13:00 (下午1点)"
echo ""
echo "日志位置："
echo "  - 详细日志: /var/log/formsci-update/update-YYYYMMDD.log"
echo "  - Cron日志: /var/log/formsci-update/cron.log"
echo ""
echo "手动测试命令："
echo "  bash $UPDATE_SCRIPT"
echo ""

