#!/bin/bash
#
# 每日自动更新脚本 (23:00 执行)
# 功能：
#   1. 更新今日榜单（日榜 + 总榜）
#   2. 复制明天的赛题文件到 assets/files/
#   3. 更新 downloads.json
#   4. 提交并推送到 GitHub
#

set -e

# ==========================================
# 手动模式说明（2025-决赛调整）
# 当前站点的赛题与排行榜已切换为“人工手动更新”模式，
# 不再通过定时任务自动拉取/生成每日赛题与榜单。
# 为避免误触发自动提交，这里直接快速退出。
echo "🔕 daily_update.sh 已停用：当前使用手动更新模式，不再自动更新下载文件或排行榜。"
exit 0

# ==================== 配置区 ====================

REPO_DIR="/var/www/formallm1"
BRANCH="main"
API_KEY="${1:-default_api_key}"

# 赛题预置目录（你手动上传赛题文件的地方）
PROBLEMS_SOURCE_DIR="/var/www/formallm1_problems"

# Git 配置
GIT_USER_NAME="FormaLLM Bot"
GIT_USER_EMAIL="bot@formallm.example.com"

# 日志
LOG_DIR="$REPO_DIR/logs"
LOG_FILE="$LOG_DIR/daily_$(date +%Y%m%d).log"

# ==================== 函数 ====================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "❌ 错误: $1"
    exit 1
}

# ==================== 主流程 ====================

mkdir -p "$LOG_DIR"
mkdir -p "$PROBLEMS_SOURCE_DIR"

log "=========================================="
log "🌙 每日自动更新开始 (23:00)"
log "=========================================="

cd "$REPO_DIR" || error_exit "无法进入仓库目录"

# 1. 配置 Git
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

# 2. 拉取最新代码
log "🔄 拉取最新代码..."
git pull origin "$BRANCH" || log "⚠️  拉取失败，继续..."

# 3. 更新排行榜（今日日榜 + 总榜）
log "📊 更新排行榜..."
FETCH_LEADERBOARD="$REPO_DIR/server/fetch_leaderboard.py"
if python3 "$FETCH_LEADERBOARD" "$API_KEY" >> "$LOG_FILE" 2>&1; then
    log "✅ 排行榜更新成功"
else
    log "⚠️  排行榜更新失败"
fi

# 4. 准备明天的赛题
TOMORROW=$(date -d "+1 day" +%Y-%m-%d)
TOMORROW_MMDD=$(date -d "+1 day" +%m%d)

log "📝 准备明天 ($TOMORROW) 的赛题..."

# 检查预置文件是否存在
LEAN_SOURCE="$PROBLEMS_SOURCE_DIR/lean_${TOMORROW_MMDD}.jsonl"
LITEX_SOURCE="$PROBLEMS_SOURCE_DIR/litex_${TOMORROW_MMDD}.jsonl"

LEAN_TARGET="$REPO_DIR/assets/files/lean_${TOMORROW_MMDD}.jsonl"
LITEX_TARGET="$REPO_DIR/assets/files/litex_${TOMORROW_MMDD}.jsonl"

HAS_PROBLEMS=false

if [ -f "$LEAN_SOURCE" ]; then
    cp "$LEAN_SOURCE" "$LEAN_TARGET"
    log "✅ Lean 赛题已复制: lean_${TOMORROW_MMDD}.jsonl"
    HAS_PROBLEMS=true
else
    log "ℹ️  未找到 Lean 赛题: $LEAN_SOURCE"
fi

if [ -f "$LITEX_SOURCE" ]; then
    cp "$LITEX_SOURCE" "$LITEX_TARGET"
    log "✅ Litex 赛题已复制: litex_${TOMORROW_MMDD}.jsonl"
    HAS_PROBLEMS=true
else
    log "ℹ️  未找到 Litex 赛题: $LITEX_SOURCE"
fi

# 5. 如果有赛题文件，更新 downloads.json
if [ "$HAS_PROBLEMS" = true ]; then
    log "📝 更新 downloads.json..."
    python3 - <<EOF
import json
import os
import hashlib
from datetime import datetime, timedelta

downloads_file = "$REPO_DIR/assets/data/downloads.json"

with open(downloads_file, 'r', encoding='utf-8') as f:
    config = json.load(f)

tomorrow = datetime.now() + timedelta(days=1)
date_str = tomorrow.strftime('%Y-%m-%d %H:%M:%S')
title = tomorrow.strftime('%m月%d日赛题')

items = []

# Lean 赛题
lean_file = "$LEAN_TARGET"
if os.path.exists(lean_file):
    with open(lean_file, 'rb') as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    items.append({
        "md5": md5,
        "url": "https://www.xir.cn/competitions/1143",
        "local": "assets/files/lean_${TOMORROW_MMDD}.jsonl",
        "available": True
    })

# Litex 赛题
litex_file = "$LITEX_TARGET"
if os.path.exists(litex_file):
    with open(litex_file, 'rb') as f:
        md5 = hashlib.md5(f.read()).hexdigest()
    items.append({
        "md5": md5,
        "url": "https://www.xir.cn/competitions/1143",
        "local": "assets/files/litex_${TOMORROW_MMDD}.jsonl",
        "available": True
    })

if items:
    new_dataset = {
        "timestamp": date_str,
        "title": title,
        "note": "报名后可下载数据",
        "items": items
    }
    
    # 检查是否已存在
    existing_index = None
    for i, dataset in enumerate(config["datasets"]):
        if dataset.get("title") == title:
            existing_index = i
            break
    
    if existing_index is not None:
        config["datasets"][existing_index] = new_dataset
    else:
        config["datasets"].insert(0, new_dataset)
    
    config["lastUpdated"] = datetime.now().isoformat()
    
    with open(downloads_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    
    print("✅ downloads.json 已更新")
EOF
    log "✅ downloads.json 更新完成"
fi

# 6. 检查是否有变更
git add -A assets/data/ assets/files/*.jsonl 2>/dev/null || true

if git diff --staged --quiet; then
    log "ℹ️  无变更，退出"
    log "=========================================="
    exit 0
fi

# 7. 提交并推送
log "📝 提交变更..."
COMMIT_MSG="chore: daily update $(date '+%Y-%m-%d %H:%M')"
git commit -m "$COMMIT_MSG" || error_exit "提交失败"
log "✅ 提交成功"

log "⬆️  推送到 GitHub..."
if git push origin "$BRANCH"; then
    log "✅ 推送成功"
else
    error_exit "推送失败"
fi

log "=========================================="
log "✅ 每日更新完成"
log "=========================================="

exit 0
