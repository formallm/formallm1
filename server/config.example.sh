#!/bin/bash
# ForMaLLM 竞赛排行榜配置示例
# 使用方法：
#   1. 复制此文件为 config.sh: cp config.example.sh config.sh
#   2. 修改 config.sh 中的值
#   3. 在脚本中加载: source config.sh

# API 配置
export API_BASE_URL="http://121.41.231.229"
export API_KEY="your_api_key_here"

# 比赛阶段
# 可选值: preliminary (初赛) 或 practice (练习赛)
export STAGE="preliminary"

# GitHub 配置（用于自动推送）
export GITHUB_USER="your-username"
export GITHUB_EMAIL="your-email@example.com"

# 仓库配置
export REPO_PATH="/var/www/alailab"
export BRANCH="main"

# 日志配置
export LOG_DIR="logs"

# 可选：钉钉/企业微信 Webhook（用于通知）
# export WEBHOOK_URL="https://your-webhook-url"

