#!/bin/bash
###############################################################################
# 每日赛题同步脚本
# 功能：检测并同步第二天的赛题文件到 Git 仓库
# 使用：bash sync_daily_problems.sh
###############################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FILES_DIR="$PROJECT_ROOT/assets/files"
DATA_DIR="$PROJECT_ROOT/assets/data"

# 日志
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/sync_$(date +%Y%m%d).log"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

###############################################################################
# 主函数
###############################################################################

main() {
    log "=========================================="
    log "📦 开始同步每日赛题文件"
    log "=========================================="
    
    cd "$PROJECT_ROOT"
    
    # 计算第二天的日期（格式：MMDD）
    TOMORROW=$(date -d "tomorrow" +%m%d 2>/dev/null || date -v+1d +%m%d 2>/dev/null)
    
    if [ -z "$TOMORROW" ]; then
        log_error "无法计算第二天日期"
        exit 1
    fi
    
    log_info "第二天日期: $TOMORROW"
    
    # 检查赛题文件是否存在
    LEAN_FILE="lean_${TOMORROW}.jsonl"
    LITEX_FILE="litex_${TOMORROW}.jsonl"
    
    LEAN_PATH="$FILES_DIR/$LEAN_FILE"
    LITEX_PATH="$FILES_DIR/$LITEX_FILE"
    
    FOUND_FILES=0
    NEW_FILES=""
    
    # 检查 Lean 文件
    if [ -f "$LEAN_PATH" ]; then
        log "✅ 发现 Lean 赛题: $LEAN_FILE"
        NEW_FILES="$NEW_FILES $LEAN_PATH"
        FOUND_FILES=$((FOUND_FILES + 1))
    else
        log_warn "未找到 Lean 赛题: $LEAN_FILE"
    fi
    
    # 检查 Litex 文件
    if [ -f "$LITEX_PATH" ]; then
        log "✅ 发现 Litex 赛题: $LITEX_FILE"
        NEW_FILES="$NEW_FILES $LITEX_PATH"
        FOUND_FILES=$((FOUND_FILES + 1))
    else
        log_warn "未找到 Litex 赛题: $LITEX_FILE"
    fi
    
    # 如果没有找到任何文件
    if [ $FOUND_FILES -eq 0 ]; then
        log_warn "第二天 ($TOMORROW) 的赛题文件尚未准备好"
        log_info "请手动将文件放置到: $FILES_DIR/"
        log_info "文件名格式: lean_MMDD.jsonl 和 litex_MMDD.jsonl"
        exit 0
    fi
    
    # 检查文件是否已经在 Git 中
    NEED_ADD=0
    for file in $NEW_FILES; do
        if ! git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            NEED_ADD=1
            break
        fi
    done
    
    if [ $NEED_ADD -eq 0 ]; then
        # 检查是否有修改
        if git diff --quiet $NEW_FILES && git diff --cached --quiet $NEW_FILES; then
            log_info "赛题文件已存在且无修改，跳过提交"
            exit 0
        fi
    fi
    
    # 添加文件到 Git
    log "📝 添加赛题文件到 Git..."
    git add $NEW_FILES
    
    # 生成提交信息
    COMMIT_MSG="chore: add problems for $(date -d "tomorrow" +%Y-%m-%d 2>/dev/null || date -v+1d +%Y-%m-%d 2>/dev/null)"
    
    # 检查是否有变更需要提交
    if git diff --cached --quiet; then
        log_info "没有新的变更需要提交"
        exit 0
    fi
    
    # 提交
    log "💾 提交变更..."
    git commit -m "$COMMIT_MSG" || {
        log_error "Git commit 失败"
        exit 1
    }
    
    log "✅ 提交成功: $COMMIT_MSG"
    log "找到 $FOUND_FILES 个赛题文件"
    
    log "=========================================="
    log "✅ 赛题同步完成"
    log "=========================================="
}

# 执行主函数
main "$@"

