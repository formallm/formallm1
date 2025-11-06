#!/bin/bash
###############################################################################
# Cron 定时任务配置脚本
# 功能：自动配置每天晚上 23:00 的定时任务
# 使用：bash setup_cron.sh YOUR_API_KEY
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=========================================="
echo "⏰ 配置 Cron 定时任务"
echo "=========================================="
echo -e "${NC}"

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}❌ 错误: 未提供 API Key${NC}"
    echo -e "${YELLOW}使用方法: bash setup_cron.sh YOUR_API_KEY${NC}"
    exit 1
fi

API_KEY="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}ℹ️  项目目录: $PROJECT_ROOT${NC}"
echo ""

# 定时任务配置
CRON_TIME="0 23 * * *"  # 每天 23:00
CRON_CMD="cd $PROJECT_ROOT && bash $SCRIPT_DIR/daily_update.sh $API_KEY >> $PROJECT_ROOT/logs/cron.log 2>&1"

echo -e "${BLUE}ℹ️  定时任务配置:${NC}"
echo "   执行时间: 每天 23:00"
echo "   执行脚本: daily_update.sh"
echo "   日志文件: logs/cron.log"
echo ""

# 检查 crontab 是否已存在相同任务
echo -e "${YELLOW}🔍 检查现有定时任务...${NC}"

if crontab -l 2>/dev/null | grep -q "daily_update.sh"; then
    echo -e "${YELLOW}⚠️  检测到已存在的定时任务${NC}"
    echo ""
    echo "当前任务:"
    crontab -l 2>/dev/null | grep "daily_update.sh" || true
    echo ""
    
    read -p "是否替换现有任务？(y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  保持现有配置，退出${NC}"
        exit 0
    fi
    
    # 移除旧任务
    echo -e "${YELLOW}🗑️  移除旧任务...${NC}"
    (crontab -l 2>/dev/null | grep -v "daily_update.sh") | crontab - || true
fi

# 添加新任务
echo -e "${GREEN}➕ 添加新定时任务...${NC}"

# 获取现有 crontab
CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")

# 添加新任务
(
    echo "$CURRENT_CRONTAB"
    echo ""
    echo "# FormaLLM 每日自动更新 (23:00)"
    echo "$CRON_TIME $CRON_CMD"
) | crontab -

echo -e "${GREEN}✅ 定时任务配置成功！${NC}"
echo ""

# 显示当前所有定时任务
echo -e "${CYAN}${BOLD}当前所有定时任务:${NC}"
echo "=========================================="
crontab -l
echo "=========================================="
echo ""

# 测试执行
echo -e "${YELLOW}🧪 是否立即测试执行一次？(y/N)${NC}"
read -p "> " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🚀 开始测试执行...${NC}"
    echo ""
    bash "$SCRIPT_DIR/daily_update.sh" "$API_KEY"
    echo ""
    echo -e "${GREEN}✅ 测试执行完成${NC}"
fi

echo ""
echo -e "${CYAN}${BOLD}=========================================="
echo "✅ 配置完成"
echo "==========================================${NC}"
echo ""
echo -e "${GREEN}📋 定时任务已启用:${NC}"
echo "   • 每天 23:00 自动执行"
echo "   • 更新排行榜数据"
echo "   • 同步第二天赛题"
echo "   • 自动推送到 GitHub"
echo ""
echo -e "${BLUE}📝 查看日志:${NC}"
echo "   tail -f $PROJECT_ROOT/logs/cron.log"
echo ""
echo -e "${BLUE}🔧 管理定时任务:${NC}"
echo "   查看: crontab -l"
echo "   编辑: crontab -e"
echo "   删除: crontab -r"
echo ""
echo -e "${YELLOW}⏰ 下次执行时间: 今晚 23:00${NC}"
echo ""

