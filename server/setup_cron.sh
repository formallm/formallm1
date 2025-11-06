#!/bin/bash
#
# Crontab 配置脚本
# 用法: ./setup_cron.sh [API_KEY]
#

API_KEY="${1}"

if [ -z "$API_KEY" ]; then
    echo "❌ 请提供 API Key"
    echo "用法: ./setup_cron.sh YOUR_API_KEY"
    exit 1
fi

echo "🔧 配置定时任务..."
echo ""
echo "将添加以下定时任务："
echo "  - 每天 23:00 自动更新排行榜和明天的赛题"
echo ""

# 创建临时 crontab 文件
TEMP_CRON=$(mktemp)

# 保留现有的 crontab
crontab -l > "$TEMP_CRON" 2>/dev/null || true

# 添加新任务（如果不存在）
if ! grep -q "daily_update.sh" "$TEMP_CRON"; then
    echo "" >> "$TEMP_CRON"
    echo "# FormaLLM 每日自动更新 (23:00)" >> "$TEMP_CRON"
    echo "0 23 * * * cd /var/www/formallm1/server && bash daily_update.sh '$API_KEY' >> /var/www/formallm1/logs/cron.log 2>&1" >> "$TEMP_CRON"
    echo "" >> "$TEMP_CRON"
    
    # 安装 crontab
    crontab "$TEMP_CRON"
    
    echo "✅ Crontab 配置成功！"
    echo ""
    echo "📋 当前定时任务："
    crontab -l
else
    echo "ℹ️  定时任务已存在，无需重复添加"
fi

# 清理临时文件
rm -f "$TEMP_CRON"

echo ""
echo "✅ 配置完成！"
echo ""
echo "📝 说明："
echo "  1. 每天 23:00 自动更新排行榜和第二天的赛题"
echo "  2. 赛题文件需提前上传到: /var/www/formallm1_problems/"
echo "  3. 文件命名格式: lean_MMDD.jsonl, litex_MMDD.jsonl"
echo "  4. 例如明天是 11月7日，需要: lean_1107.jsonl, litex_1107.jsonl"
echo ""
echo "🔍 查看日志:"
echo "  tail -f /var/www/formallm1/logs/cron.log"
echo "  tail -f /var/www/formallm1/logs/daily_YYYYMMDD.log"
