#!/bin/bash
#
# 自动更新排行榜脚本
# 功能：获取最新排行榜数据，提交并推送到 GitHub
#
# 使用方法：
#   ./auto_update.sh [API_KEY] [STAGE]
#
# 示例：
#   ./auto_update.sh your_api_key preliminary
#

set -e  # 遇到错误立即退出

# ==================== 配置区 ====================

# GitHub 仓库信息
REPO_DIR="/var/www/alailab"  # 仓库本地路径（请修改为您的实际路径）
BRANCH="main"                 # 推送的分支

# API 配置
API_KEY="${1:-default_api_key}"    # 第一个参数：API Key
STAGE="${2:-preliminary}"          # 第二个参数：比赛阶段

# Git 配置
GIT_USER_NAME="Leaderboard Bot"
GIT_USER_EMAIL="bot@example.com"

# 日志文件
LOG_DIR="$REPO_DIR/logs"
LOG_FILE="$LOG_DIR/update_$(date +%Y%m%d).log"

# ==================== 函数定义 ====================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ 错误: $1"
    exit 1
}

# ==================== 主流程 ====================

# 创建日志目录
mkdir -p "$LOG_DIR"

log "=========================================="
log "🚀 开始更新排行榜数据"
log "=========================================="

# 1. 检查仓库目录
if [ ! -d "$REPO_DIR" ]; then
    error_exit "仓库目录不存在: $REPO_DIR"
fi

cd "$REPO_DIR" || error_exit "无法进入仓库目录"
log "📁 工作目录: $(pwd)"

# 2. 检查 Git 状态
if [ ! -d ".git" ]; then
    error_exit "当前目录不是 Git 仓库"
fi

# 3. 配置 Git 用户信息
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"
log "✅ Git 配置完成"

# 4. 拉取最新代码
log "🔄 拉取最新代码..."
git pull origin "$BRANCH" || log "⚠️  拉取失败，继续执行..."

# 5. 检查 Python 脚本
FETCH_SCRIPT="$REPO_DIR/server/fetch_leaderboard.py"
if [ ! -f "$FETCH_SCRIPT" ]; then
    error_exit "找不到数据获取脚本: $FETCH_SCRIPT"
fi

# 6. 执行数据获取
log "📡 获取排行榜数据..."
if python3 "$FETCH_SCRIPT" "$API_KEY" "$STAGE" >> "$LOG_FILE" 2>&1; then
    log "✅ 数据获取成功"
else
    error_exit "数据获取失败"
fi

# 7. 检查是否有变更
if git diff --quiet assets/data/leaderboard.json; then
    log "ℹ️  数据无变化，无需更新"
    log "=========================================="
    exit 0
fi

# 8. 提交变更
log "📝 提交变更..."
git add assets/data/leaderboard.json

COMMIT_MSG="chore: update leaderboard data - $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG" || error_exit "提交失败"
log "✅ 提交成功: $COMMIT_MSG"

# 9. 推送到 GitHub
log "⬆️  推送到 GitHub..."
if git push origin "$BRANCH"; then
    log "✅ 推送成功"
else
    error_exit "推送失败"
fi

# 10. 完成
log "=========================================="
log "✅ 排行榜更新完成"
log "=========================================="

exit 0

