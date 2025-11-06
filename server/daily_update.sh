#!/bin/bash
###############################################################################
# 每日更新主脚本
# 功能：每天晚上 23:00 自动执行
#   1. 更新当日排行榜（日榜 + 总榜）
#   2. 同步第二天的赛题文件
#   3. 推送所有更改到 GitHub
# 
# 使用：bash daily_update.sh [API_KEY]
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

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 日志
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
DATE_STR=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/daily_${DATE_STR}.log"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️  INFO: $1${NC}" | tee -a "$LOG_FILE"
}

log_section() {
    echo -e "${CYAN}${BOLD}" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo -e "${NC}" | tee -a "$LOG_FILE"
}

###############################################################################
# 主函数
###############################################################################

main() {
    log_section "🌙 每日自动更新任务开始"
    log_info "执行时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "项目目录: $PROJECT_ROOT"
    log ""
    
    # 检查 API Key
    API_KEY="${1:-}"
    if [ -z "$API_KEY" ]; then
        log_error "未提供 API Key"
        log_info "使用方法: bash daily_update.sh YOUR_API_KEY"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # ========== 步骤 0: Git 同步 ==========
    log_section "📥 步骤 0/3: 同步远程仓库"
    
    log "拉取最新代码..."
    if git pull origin main; then
        log "✅ 代码同步成功"
    else
        log_warn "代码同步失败，继续执行..."
    fi
    log ""
    
    # ========== 步骤 1: 更新排行榜 ==========
    log_section "📊 步骤 1/3: 更新排行榜数据"
    
    log "执行排行榜更新脚本..."
    if python3 "$SCRIPT_DIR/fetch_leaderboard.py" "$API_KEY"; then
        log "✅ 排行榜更新成功"
        
        # 添加到 Git
        git add assets/data/leaderboard.json
        log "✅ 排行榜数据已暂存"
    else
        log_error "排行榜更新失败"
        log_warn "继续执行其他任务..."
    fi
    log ""
    
    # ========== 步骤 2: 同步赛题文件 ==========
    log_section "📦 步骤 2/3: 同步第二天赛题"
    
    log "执行赛题同步脚本..."
    if bash "$SCRIPT_DIR/sync_daily_problems.sh"; then
        log "✅ 赛题同步完成"
    else
        log_warn "赛题同步未找到新文件或出现问题"
    fi
    log ""
    
    # ========== 步骤 3: 提交并推送 ==========
    log_section "🚀 步骤 3/3: 提交并推送到 GitHub"
    
    # 检查是否有变更
    if git diff --cached --quiet && git diff --quiet; then
        log_info "没有变更需要提交"
        log_section "✅ 每日更新任务完成（无变更）"
        exit 0
    fi
    
    # 显示变更摘要
    log "变更摘要:"
    git status --short | tee -a "$LOG_FILE"
    log ""
    
    # 添加所有变更（防止遗漏）
    git add -A
    
    # 生成提交消息
    TODAY=$(date +%Y-%m-%d)
    COMMIT_MSG="chore: daily update - leaderboard and problems for ${TODAY}"
    
    # 提交
    log "💾 提交变更..."
    if git commit -m "$COMMIT_MSG"; then
        log "✅ 提交成功"
    else
        log_warn "提交失败或无需提交"
    fi
    
    # 推送到 GitHub
    log "📤 推送到 GitHub..."
    if git push origin main; then
        log "✅ 推送成功"
    else
        log_error "推送失败"
        log_info "请检查网络连接和 Git 权限"
        exit 1
    fi
    
    log ""
    log_section "✅ 每日更新任务全部完成"
    log_info "更新内容:"
    log_info "  ✓ 排行榜数据（当日日榜 + 总榜）"
    log_info "  ✓ 第二天赛题文件（如果存在）"
    log_info "  ✓ 已推送到 GitHub Pages"
    log ""
    log "🎉 网站将在 1-2 分钟内自动更新"
}

# 错误处理
trap 'log_error "脚本执行出错，退出码: $?"' ERR

# 执行主函数
main "$@"

