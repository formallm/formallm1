#!/bin/bash
#
# 云服务器快速配置脚本
# 一键完成大部分配置工作
#

set -e

echo "=============================================="
echo "🚀 FormaLLM 云服务器自动更新 - 快速配置"
echo "=============================================="
echo

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ==================== 检查环境 ====================

echo "📋 步骤 1/7: 检查系统环境"
echo "----------------------------------------"

# 检查操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  操作系统: $NAME $VERSION"
else
    print_warning "无法识别操作系统"
fi

# 检查当前目录
CURRENT_DIR=$(pwd)
echo "  当前目录: $CURRENT_DIR"

# 检查是否在项目目录
if [ ! -f "server/fetch_leaderboard.py" ]; then
    print_error "请在项目根目录（formallm1）下运行此脚本"
    echo "  当前目录: $CURRENT_DIR"
    echo "  正确目录应该包含: server/fetch_leaderboard.py"
    exit 1
fi

REPO_DIR=$CURRENT_DIR
print_success "项目目录确认: $REPO_DIR"
echo

# ==================== 安装依赖 ====================

echo "📦 步骤 2/7: 安装系统依赖"
echo "----------------------------------------"

if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python3 已安装: $PYTHON_VERSION"
else
    echo "正在安装 Python3..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3 python3-pip
    else
        print_error "无法自动安装，请手动安装 python3"
        exit 1
    fi
    print_success "Python3 安装完成"
fi

if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    print_success "Git 已安装: $GIT_VERSION"
else
    echo "正在安装 Git..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y git
    elif command -v yum &> /dev/null; then
        sudo yum install -y git
    fi
    print_success "Git 安装完成"
fi

echo "正在安装 Python 依赖..."
pip3 install -q --user requests || sudo pip3 install -q requests
print_success "Python 依赖安装完成"
echo

# ==================== 配置 Git ====================

echo "🔧 步骤 3/7: 配置 Git"
echo "----------------------------------------"

# 检查是否已配置
CURRENT_NAME=$(git config user.name || echo "")
CURRENT_EMAIL=$(git config user.email || echo "")

if [ -n "$CURRENT_NAME" ] && [ -n "$CURRENT_EMAIL" ]; then
    echo "  当前配置:"
    echo "    用户名: $CURRENT_NAME"
    echo "    邮箱: $CURRENT_EMAIL"
    echo
    read -p "是否保留当前配置？(y/n): " keep_config
    if [ "$keep_config" != "y" ]; then
        read -p "输入 Git 用户名: " git_name
        read -p "输入 Git 邮箱: " git_email
        git config user.name "$git_name"
        git config user.email "$git_email"
        print_success "Git 配置已更新"
    else
        print_success "保留现有 Git 配置"
    fi
else
    read -p "输入 Git 用户名 (如: Leaderboard Bot): " git_name
    read -p "输入 Git 邮箱 (如: bot@formallm.com): " git_email
    git config user.name "$git_name"
    git config user.email "$git_email"
    print_success "Git 配置完成"
fi
echo

# ==================== 配置 GitHub 推送 ====================

echo "🔑 步骤 4/7: 配置 GitHub 推送权限"
echo "----------------------------------------"
echo "请选择认证方式:"
echo "  1) SSH Key（推荐）"
echo "  2) Personal Access Token"
read -p "选择 (1/2): " auth_choice

if [ "$auth_choice" = "1" ]; then
    # SSH Key
    if [ ! -f ~/.ssh/formallm_deploy ]; then
        echo "正在生成 SSH 密钥..."
        ssh-keygen -t ed25519 -C "bot@formallm.com" -f ~/.ssh/formallm_deploy -N ""
        
        echo
        echo "=========================================="
        print_warning "请将以下公钥添加到 GitHub"
        echo "=========================================="
        cat ~/.ssh/formallm_deploy.pub
        echo "=========================================="
        echo
        echo "步骤:"
        echo "1. 访问: https://github.com/YOUR-USERNAME/alailab/settings/keys"
        echo "2. 点击 'Add deploy key'"
        echo "3. Title: Cloud Server Auto Update"
        echo "4. Key: 粘贴上面的公钥"
        echo "5. ✅ 勾选 'Allow write access'"
        echo "6. 点击 'Add key'"
        echo
        read -p "完成后按回车继续..."
        
        # 配置 SSH config
        mkdir -p ~/.ssh
        if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
            cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/formallm_deploy
    IdentitiesOnly yes
EOF
            chmod 600 ~/.ssh/config
        fi
    else
        print_success "SSH 密钥已存在"
    fi
    
    # 测试 SSH 连接
    echo "测试 GitHub SSH 连接..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "GitHub SSH 连接成功"
    else
        print_error "SSH 连接失败，请检查 Deploy Key 配置"
        exit 1
    fi

elif [ "$auth_choice" = "2" ]; then
    # Personal Access Token
    echo "请访问以下网址生成 Token:"
    echo "https://github.com/settings/tokens/new"
    echo "权限: 勾选 'repo' (完整权限)"
    echo
    read -sp "输入您的 GitHub Personal Access Token: " github_token
    echo
    
    git config --global credential.helper store
    echo "https://${github_token}@github.com" > ~/.git-credentials
    chmod 600 ~/.git-credentials
    print_success "GitHub Token 配置完成"
else
    print_error "无效的选择"
    exit 1
fi
echo

# ==================== 配置 API Key ====================

echo "🔐 步骤 5/7: 配置 API 访问"
echo "----------------------------------------"
read -sp "输入 FormaLLM API Key: " api_key
echo
read -p "输入比赛阶段 (preliminary/practice, 默认 preliminary): " stage
stage=${stage:-preliminary}

API_KEY_TO_USE=$api_key
STAGE_TO_USE=$stage

print_success "API 配置完成"
echo

# ==================== 测试脚本 ====================

echo "🧪 步骤 6/7: 测试数据获取"
echo "----------------------------------------"

# 设置脚本权限
chmod +x server/*.sh
chmod +x server/*.py

echo "测试排行榜数据获取..."
if python3 server/fetch_leaderboard.py "$API_KEY_TO_USE" "$STAGE_TO_USE"; then
    print_success "排行榜数据获取成功"
else
    print_warning "排行榜数据获取失败，但继续配置..."
fi

echo
echo "测试赛题数据获取..."
if python3 server/fetch_problems.py "$API_KEY_TO_USE"; then
    print_success "赛题数据获取成功"
else
    print_warning "赛题数据获取失败（可能今日无新题）"
fi

echo

# ==================== 配置定时任务 ====================

echo "⏰ 步骤 7/7: 配置定时任务"
echo "----------------------------------------"
echo "请选择更新频率:"
echo "  1) 每天 2:00 和 14:00（推荐）"
echo "  2) 每小时"
echo "  3) 每 30 分钟"
echo "  4) 每天 3:00"
echo "  5) 自定义"
read -p "选择 (1-5): " freq_choice

case $freq_choice in
    1)
        CRON_SCHEDULE="0 2,14 * * *"
        DESCRIPTION="每天 2:00 和 14:00"
        ;;
    2)
        CRON_SCHEDULE="0 * * * *"
        DESCRIPTION="每小时"
        ;;
    3)
        CRON_SCHEDULE="*/30 * * * *"
        DESCRIPTION="每 30 分钟"
        ;;
    4)
        CRON_SCHEDULE="0 3 * * *"
        DESCRIPTION="每天 3:00"
        ;;
    5)
        read -p "输入 Cron 表达式 (如 0 */2 * * *): " CRON_SCHEDULE
        DESCRIPTION="自定义"
        ;;
    *)
        print_error "无效选择，使用默认配置"
        CRON_SCHEDULE="0 2,14 * * *"
        DESCRIPTION="每天 2:00 和 14:00"
        ;;
esac

# 创建日志目录
mkdir -p logs

# 构建 Cron 命令
CRON_CMD="$CRON_SCHEDULE cd $REPO_DIR && bash server/auto_update.sh $API_KEY_TO_USE $STAGE_TO_USE >> logs/cron.log 2>&1"

# 检查是否已存在
if crontab -l 2>/dev/null | grep -q "auto_update.sh"; then
    print_warning "定时任务已存在，跳过添加"
else
    # 添加到 crontab
    (crontab -l 2>/dev/null || true; echo "# FormaLLM Auto Update"; echo "$CRON_CMD") | crontab -
    print_success "定时任务已添加: $DESCRIPTION"
fi

echo

# ==================== 显示总结 ====================

echo "=============================================="
print_success "🎉 配置完成！"
echo "=============================================="
echo
echo "📋 配置摘要:"
echo "  • 项目目录: $REPO_DIR"
echo "  • Python: $(python3 --version 2>&1)"
echo "  • Git: $(git --version 2>&1)"
echo "  • Git 用户: $(git config user.name)"
echo "  • 更新频率: $DESCRIPTION"
echo "  • 比赛阶段: $STAGE_TO_USE"
echo
echo "📝 下一步操作:"
echo "  1. 查看定时任务: crontab -l"
echo "  2. 手动测试: bash server/auto_update.sh $API_KEY_TO_USE $STAGE_TO_USE"
echo "  3. 查看日志: tail -f logs/cron.log"
echo "  4. 等待定时任务执行，或手动触发测试"
echo
echo "🔍 验证部署:"
echo "  • 等待定时任务执行后"
echo "  • 访问 GitHub 查看自动提交"
echo "  • 访问网站查看数据更新"
echo
echo "📚 更多帮助:"
echo "  • 完整指南: cat SERVER_DEPLOYMENT_GUIDE.md"
echo "  • 脚本说明: cat server/README.md"
echo
print_success "部署完成！系统将自动更新排行榜和赛题数据。"
echo "=============================================="


