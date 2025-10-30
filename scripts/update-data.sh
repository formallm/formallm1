#!/bin/bash
#
# 自动更新排行榜和赛题数据脚本
# 用于云服务器定时任务，自动拉取数据并推送到 GitHub
#

set -e  # 遇到错误立即退出

# ============ 配置区域 ============
# 数据源API地址（您的白名单服务器）
LEADERBOARD_API="http://121.43.230.124/results/leaderboard"
PROBLEMS_API="http://121.43.230.124/results/daily/{{DATE}}"  # {{DATE}} 会被替换为当前日期

# GitHub仓库本地路径
REPO_DIR="/var/www/formsci"

# 目标文件路径
LEADERBOARD_FILE="assets/data/leaderboard.json"
DOWNLOADS_FILE="assets/data/downloads.json"

# Git配置
GIT_USER_NAME="Auto Update Bot"
GIT_USER_EMAIL="bot@example.com"
GIT_BRANCH="main"  # 或 "gh-pages"，根据您的部署分支

# 日志文件
LOG_DIR="/var/log/formsci-update"
LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d).log"

# ============ 函数定义 ============

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 错误处理
error_exit() {
    log "ERROR: $1"
    exit 1
}

# 验证JSON格式
validate_json() {
    local file=$1
    if ! jq empty "$file" 2>/dev/null; then
        return 1
    fi
    return 0
}

# 获取排行榜数据
fetch_leaderboard() {
    log "开始获取排行榜数据..."
    
    local temp_file="${LEADERBOARD_FILE}.tmp"
    
    # 使用curl获取数据，30秒超时
    if curl -f -s -S --max-time 30 -o "$temp_file" "$LEADERBOARD_API"; then
        log "排行榜数据下载成功"
        
        # 验证JSON格式
        if validate_json "$temp_file"; then
            mv "$temp_file" "$LEADERBOARD_FILE"
            log "排行榜数据已更新: $LEADERBOARD_FILE"
            return 0
        else
            log "ERROR: 排行榜数据JSON格式无效"
            rm -f "$temp_file"
            return 1
        fi
    else
        log "ERROR: 无法获取排行榜数据"
        rm -f "$temp_file"
        return 1
    fi
}

# 获取今日赛题数据
fetch_daily_problems() {
    log "开始获取今日赛题数据..."
    
    local today=$(date +%Y-%m-%d)
    local api_url="${PROBLEMS_API//\{\{DATE\}\}/$today}"
    local temp_file="${DOWNLOADS_FILE}.tmp"
    
    log "请求URL: $api_url"
    
    # 获取赛题数据
    if curl -f -s -S --max-time 30 -o "$temp_file" "$api_url"; then
        log "赛题数据下载成功"
        
        # 验证JSON格式
        if validate_json "$temp_file"; then
            # 读取现有的downloads.json
            if [ -f "$DOWNLOADS_FILE" ]; then
                # 合并新数据到现有文件（保留其他配置）
                # 这里使用jq合并数据，您可以根据实际API返回格式调整
                jq --slurpfile new "$temp_file" \
                   '.lastUpdated = now | .datasets[0].timestamp = "'$(date '+%Y-%m-%d %H:%M:%S')'" | .datasets[0].items = $new[0]' \
                   "$DOWNLOADS_FILE" > "${DOWNLOADS_FILE}.new"
                
                if validate_json "${DOWNLOADS_FILE}.new"; then
                    mv "${DOWNLOADS_FILE}.new" "$DOWNLOADS_FILE"
                    log "赛题数据已更新: $DOWNLOADS_FILE"
                else
                    log "WARN: 合并后的JSON格式无效，跳过更新"
                    rm -f "${DOWNLOADS_FILE}.new"
                fi
            else
                log "WARN: $DOWNLOADS_FILE 不存在，跳过赛题更新"
            fi
            
            rm -f "$temp_file"
            return 0
        else
            log "ERROR: 赛题数据JSON格式无效"
            rm -f "$temp_file"
            return 1
        fi
    else
        log "ERROR: 无法获取赛题数据（可能今日无新题目）"
        rm -f "$temp_file"
        return 1
    fi
}

# 推送到GitHub
push_to_github() {
    log "开始推送到GitHub..."
    
    cd "$REPO_DIR" || error_exit "无法进入仓库目录: $REPO_DIR"
    
    # 配置Git用户信息
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"
    
    # 拉取最新代码，避免冲突
    log "拉取远程最新代码..."
    if ! git pull origin "$GIT_BRANCH" --rebase; then
        log "WARN: 拉取代码失败，尝试继续..."
    fi
    
    # 添加修改的文件
    git add "$LEADERBOARD_FILE" "$DOWNLOADS_FILE" 2>/dev/null || true
    
    # 检查是否有变化
    if git diff --staged --quiet; then
        log "没有数据变化，跳过提交"
        return 0
    fi
    
    # 提交变更
    local commit_msg="Auto update: leaderboard and problems data at $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$commit_msg"; then
        log "提交成功: $commit_msg"
        
        # 推送到GitHub
        if git push origin "$GIT_BRANCH"; then
            log "推送成功到 GitHub"
            return 0
        else
            error_exit "推送到GitHub失败"
        fi
    else
        log "WARN: 提交失败，可能没有变化"
        return 1
    fi
}

# ============ 主流程 ============

main() {
    log "=========================================="
    log "开始执行自动更新任务"
    log "=========================================="
    
    # 创建日志目录
    mkdir -p "$LOG_DIR"
    
    # 检查依赖
    for cmd in curl jq git; do
        if ! command -v $cmd &> /dev/null; then
            error_exit "$cmd 未安装，请先安装"
        fi
    done
    
    # 进入仓库目录
    cd "$REPO_DIR" || error_exit "无法进入仓库目录: $REPO_DIR"
    
    # 标记是否有数据更新
    updated=false
    
    # 1. 获取排行榜数据
    if fetch_leaderboard; then
        updated=true
    fi
    
    # 2. 获取今日赛题数据
    if fetch_daily_problems; then
        updated=true
    fi
    
    # 3. 如果有数据更新，推送到GitHub
    if [ "$updated" = true ]; then
        push_to_github
    else
        log "没有数据更新，跳过推送"
    fi
    
    log "=========================================="
    log "自动更新任务完成"
    log "=========================================="
}

# 执行主函数
main "$@"

