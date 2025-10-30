#!/bin/bash
#
# 云服务器环境配置脚本
# 功能：安装依赖、配置定时任务
#

set -e

echo "=========================================="
echo "🔧 ForMaLLM 排行榜自动更新 - 环境配置"
echo "=========================================="
echo

# ==================== 检查系统 ====================

echo "📋 检查系统信息..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  操作系统: $NAME $VERSION"
else
    echo "  ⚠️  无法识别操作系统"
fi
echo

# ==================== 安装依赖 ====================

echo "📦 安装 Python3 和 pip..."
if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip git
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    sudo yum install -y python3 python3-pip git
elif command -v dnf &> /dev/null; then
    # Fedora
    sudo dnf install -y python3 python3-pip git
else
    echo "❌ 无法识别包管理器，请手动安装 python3, pip, git"
    exit 1
fi
echo "✅ 系统依赖安装完成"
echo

# ==================== 安装 Python 依赖 ====================

echo "📦 安装 Python 依赖包..."
pip3 install --user requests
echo "✅ Python 依赖安装完成"
echo

# ==================== 设置脚本权限 ====================

echo "🔐 设置脚本执行权限..."
chmod +x server/fetch_leaderboard.py
chmod +x server/auto_update.sh
echo "✅ 权限设置完成"
echo

# ==================== 配置 Git ====================

echo "🔧 配置 Git..."
echo "请输入 GitHub 用户名:"
read -r git_username
echo "请输入 GitHub 邮箱:"
read -r git_email

git config --global user.name "$git_username"
git config --global user.email "$git_email"
echo "✅ Git 配置完成"
echo

# ==================== 配置 GitHub Token ====================

echo "🔑 配置 GitHub 访问令牌..."
echo "请访问 https://github.com/settings/tokens 生成 Personal Access Token"
echo "需要权限: repo (完整权限)"
echo
echo "请输入您的 GitHub Token:"
read -rs github_token
echo

# 配置 Git Credential Helper
git config --global credential.helper store
echo "https://${github_token}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
echo "✅ GitHub Token 配置完成"
echo

# ==================== 测试脚本 ====================

echo "🧪 测试数据获取脚本..."
echo "请输入 API Key (默认: default_api_key):"
read -r api_key
api_key=${api_key:-default_api_key}

echo "请输入比赛阶段 (preliminary/practice，默认: preliminary):"
read -r stage
stage=${stage:-preliminary}

if python3 server/fetch_leaderboard.py "$api_key" "$stage"; then
    echo "✅ 测试成功"
else
    echo "❌ 测试失败，请检查 API Key 和网络连接"
fi
echo

# ==================== 配置定时任务 ====================

echo "⏰ 配置定时任务 (Cron)..."
echo "当前工作目录: $(pwd)"
SCRIPT_PATH="$(pwd)/server/auto_update.sh"

echo "请选择更新频率:"
echo "  1) 每小时"
echo "  2) 每 6 小时"
echo "  3) 每天 8:00"
echo "  4) 每天 8:00 和 20:00"
echo "  5) 自定义"
read -r choice

case $choice in
    1)
        CRON_SCHEDULE="0 * * * *"
        DESCRIPTION="每小时"
        ;;
    2)
        CRON_SCHEDULE="0 */6 * * *"
        DESCRIPTION="每 6 小时"
        ;;
    3)
        CRON_SCHEDULE="0 8 * * *"
        DESCRIPTION="每天 8:00"
        ;;
    4)
        CRON_SCHEDULE="0 8,20 * * *"
        DESCRIPTION="每天 8:00 和 20:00"
        ;;
    5)
        echo "请输入 Cron 表达式 (例如: 0 */2 * * *):"
        read -r CRON_SCHEDULE
        DESCRIPTION="自定义"
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

# 添加到 crontab
CRON_COMMAND="$CRON_SCHEDULE cd $(pwd) && $SCRIPT_PATH $api_key $stage >> logs/cron.log 2>&1"
(crontab -l 2>/dev/null || true; echo "$CRON_COMMAND") | crontab -

echo "✅ 定时任务配置完成: $DESCRIPTION"
echo "   Cron 表达式: $CRON_SCHEDULE"
echo

# ==================== 显示总结 ====================

echo "=========================================="
echo "✅ 环境配置完成！"
echo "=========================================="
echo
echo "📋 配置摘要:"
echo "  • Python3: $(python3 --version)"
echo "  • Git: $(git --version)"
echo "  • 仓库路径: $(pwd)"
echo "  • 脚本路径: $SCRIPT_PATH"
echo "  • 更新频率: $DESCRIPTION"
echo "  • API Key: $api_key"
echo "  • 比赛阶段: $stage"
echo
echo "📝 下一步:"
echo "  1. 查看定时任务: crontab -l"
echo "  2. 手动执行测试: $SCRIPT_PATH"
echo "  3. 查看日志: tail -f logs/cron.log"
echo "  4. 如需修改配置，编辑: server/auto_update.sh"
echo
echo "🎉 配置完成！系统将自动更新排行榜数据。"
echo "=========================================="

