#!/bin/bash
#
# 配置GitHub SSH密钥和仓库
#

set -e

echo "=== 配置GitHub自动推送 ==="

# 配置参数（请根据实际情况修改）
GITHUB_USER="your-username"
GITHUB_REPO="alailab"
REPO_URL="git@github.com:${GITHUB_USER}/${GITHUB_REPO}.git"
REPO_DIR="/var/www/formsci"

echo ""
echo "1. 检查SSH密钥..."

# 检查SSH密钥
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "未找到SSH密钥，正在生成..."
    ssh-keygen -t rsa -b 4096 -C "bot@example.com" -f ~/.ssh/id_rsa -N ""
    echo "✓ SSH密钥已生成"
    echo ""
    echo "请将以下公钥添加到GitHub仓库的Deploy Keys："
    echo "仓库设置 -> Deploy keys -> Add deploy key"
    echo "标题: Auto Update Bot"
    echo "勾选: Allow write access"
    echo ""
    cat ~/.ssh/id_rsa.pub
    echo ""
    read -p "添加完成后按回车继续..."
else
    echo "✓ SSH密钥已存在"
fi

echo ""
echo "2. 测试GitHub连接..."

# 测试GitHub连接
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✓ GitHub SSH连接成功"
else
    echo "⚠ GitHub SSH连接测试失败，请检查Deploy Key配置"
    echo "执行以下命令测试："
    echo "  ssh -T git@github.com"
    exit 1
fi

echo ""
echo "3. 配置Git仓库..."

# 检查是否已是Git仓库
if [ -d "$REPO_DIR/.git" ]; then
    echo "✓ Git仓库已存在"
    cd "$REPO_DIR"
    
    # 检查remote
    if git remote | grep -q "origin"; then
        echo "✓ Remote origin 已配置"
        git remote -v
    else
        git remote add origin "$REPO_URL"
        echo "✓ 已添加 remote origin"
    fi
else
    echo "初始化Git仓库..."
    cd "$REPO_DIR"
    git init
    git remote add origin "$REPO_URL"
    git branch -M main
    echo "✓ Git仓库已初始化"
fi

echo ""
echo "4. 配置Git用户信息..."

git config user.name "Auto Update Bot"
git config user.email "bot@example.com"

echo "✓ Git用户信息已配置"

echo ""
echo "5. 测试推送..."

# 创建测试提交
echo "# Test commit at $(date)" > .test-commit
git add .test-commit
if git commit -m "Test commit from server" 2>/dev/null; then
    if git push origin main; then
        echo "✓ 测试推送成功"
        # 删除测试文件
        git rm .test-commit
        git commit -m "Remove test commit"
        git push origin main
    else
        echo "✗ 推送失败，请检查权限配置"
        exit 1
    fi
else
    echo "⚠ 无需提交（仓库已是最新）"
fi

echo ""
echo "=== 配置完成 ==="
echo ""
echo "GitHub仓库: $REPO_URL"
echo "本地路径: $REPO_DIR"
echo ""
echo "后续步骤："
echo "1. 编辑 scripts/update-data.sh，修改API地址"
echo "2. 运行 bash scripts/setup-cron.sh 配置定时任务"
echo "3. 运行 bash scripts/update-data.sh 测试更新脚本"
echo ""

