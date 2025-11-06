# 云服务器自动更新部署指南

## 📋 部署概览

### 架构图
```
┌─────────────────────┐
│   本地开发电脑       │
│  - 修改代码          │
│  - git push          │
└──────────┬──────────┘
           │
           ↓ push
┌──────────────────────────────────────┐
│        GitHub Repository              │
│  - 存储代码                           │
│  - 存储数据文件                       │
└──────┬───────────────────────┬────────┘
       │                       │
       │ pull (定时)           │ auto deploy
       ↓                       ↓
┌──────────────────┐    ┌────────────────┐
│   云服务器        │    │  GitHub Pages  │
│  - 定时任务       │    │  - 静态网站     │
│  - 获取API数据    │    │  - 用户访问     │
│  - 推送到GitHub   │    └────────────────┘
└──────┬───────────┘
       │
       ↓ API请求
┌──────────────────┐
│  FormaLLM API    │
│  - 排行榜数据     │
│  - 赛题数据       │
└──────────────────┘
```

## 🎯 目标

实现以下自动化流程：
1. 云服务器每天定时从 API 获取排行榜数据
2. 云服务器每天定时从 API 获取当日赛题文件
3. 自动提交并推送到 GitHub
4. GitHub Pages 自动部署更新后的网站

## ✅ 准备工作（在本地完成）

### 1. 确认文件已推送到 GitHub

```powershell
# 在本地电脑上（formallm1 目录）
cd D:\HuaweiMoveData\Users\NERV\Desktop\alailab

# 添加所有文件
git add formallm1/

# 提交
git commit -m "Add server scripts for auto-update"

# 推送到 GitHub
git push origin main
```

### 2. 获取必要的凭据

需要准备：
- ✅ **GitHub 仓库地址**（如：`git@github.com:your-username/alailab.git`）
- ✅ **API Key**（用于访问 FormaLLM API）
- ✅ **API 端点**（如：`http://121.43.230.124`）

## 🚀 云服务器部署步骤

### 步骤 1: SSH 登录到云服务器

```bash
ssh your-username@your-server-ip
```

### 步骤 2: 克隆仓库到云服务器

```bash
# 创建工作目录
sudo mkdir -p /var/www
cd /var/www

# 克隆 GitHub 仓库
# 方式 A: HTTPS（需要 Token）
git clone https://github.com/your-username/alailab.git formallm1

# 方式 B: SSH（推荐）
git clone git@github.com:your-username/alailab.git formallm1

# 进入项目目录
cd formallm1
```

### 步骤 3: 安装依赖

```bash
# 安装系统依赖
sudo apt-get update
sudo apt-get install -y python3 python3-pip git

# 安装 Python 依赖
cd /var/www/formallm1
pip3 install -r server/requirements.txt
```

### 步骤 4: 配置 GitHub 推送权限

#### 方式 A: 使用 SSH Key（推荐）

```bash
# 1. 生成 SSH 密钥
ssh-keygen -t ed25519 -C "bot@formallm.com" -f ~/.ssh/formallm_deploy -N ""

# 2. 查看公钥
cat ~/.ssh/formallm_deploy.pub

# 复制输出的公钥
```

**在 GitHub 上操作：**
1. 访问：`https://github.com/your-username/alailab/settings/keys`
2. 点击 **Add deploy key**
3. Title: `Cloud Server Auto Update`
4. Key: 粘贴刚才复制的公钥
5. **✅ 勾选** `Allow write access` （非常重要！）
6. 点击 **Add key**

**配置 Git 使用该密钥：**
```bash
# 配置 SSH
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/formallm_deploy
    IdentitiesOnly yes
EOF

# 测试连接
ssh -T git@github.com
# 应该看到: Hi xxx! You've successfully authenticated...
```

#### 方式 B: 使用 Personal Access Token

```bash
# 1. 访问 GitHub 生成 Token
# https://github.com/settings/tokens/new

# 2. 权限选择: repo (完整权限)

# 3. 配置 Git 凭据
git config --global credential.helper store
echo "https://YOUR_TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

### 步骤 5: 配置 Git 用户信息

```bash
cd /var/www/formallm1

git config user.name "Leaderboard Bot"
git config user.email "bot@formallm.com"
```

### 步骤 6: 设置脚本权限

```bash
chmod +x server/*.sh
chmod +x server/*.py
```

### 步骤 7: 测试脚本（手动运行）

```bash
cd /var/www/formallm1

# 测试排行榜数据获取
python3 server/fetch_leaderboard.py YOUR_API_KEY preliminary

# 检查生成的文件
cat assets/data/leaderboard.json | python3 -m json.tool

# 测试赛题数据获取（如果 API 支持）
python3 server/fetch_problems.py YOUR_API_KEY

# 测试完整流程
bash server/auto_update.sh YOUR_API_KEY preliminary
```

**检查是否成功：**
1. 查看本地文件是否更新
2. 查看 Git 提交记录：`git log -1`
3. 检查 GitHub 仓库是否有新提交

### 步骤 8: 配置定时任务（Cron）

```bash
# 编辑 crontab
crontab -e

# 添加以下内容（选择合适的更新频率）
```

**推荐配置（每天 2:00 和 14:00 更新）：**
```cron
# 自动更新排行榜和赛题（每天 2:00 和 14:00）
0 2,14 * * * cd /var/www/formallm1 && bash server/auto_update.sh YOUR_API_KEY preliminary >> logs/cron.log 2>&1
```

**其他频率选项：**
```cron
# 每小时更新一次（比赛高峰期）
0 * * * * cd /var/www/formallm1 && bash server/auto_update.sh YOUR_API_KEY preliminary >> logs/cron.log 2>&1

# 每 30 分钟更新一次
*/30 * * * * cd /var/www/formallm1 && bash server/auto_update.sh YOUR_API_KEY preliminary >> logs/cron.log 2>&1

# 每天凌晨 3:00 更新一次
0 3 * * * cd /var/www/formallm1 && bash server/auto_update.sh YOUR_API_KEY preliminary >> logs/cron.log 2>&1
```

⚠️ **重要提示**：
- 将 `YOUR_API_KEY` 替换为您的真实 API Key
- 确保路径 `/var/www/formallm1` 与实际路径一致

### 步骤 9: 创建日志目录

```bash
mkdir -p /var/www/formallm1/logs
```

### 步骤 10: 测试定时任务

```bash
# 手动执行一次，查看是否正常
cd /var/www/formallm1 && bash server/auto_update.sh YOUR_API_KEY preliminary

# 查看日志
tail -f logs/cron.log

# 查看今日详细日志
tail -f logs/update_$(date +%Y%m%d).log
```

## 📊 验证部署

### 1. 检查云服务器状态

```bash
# 查看定时任务
crontab -l

# 查看最新日志
tail -20 /var/www/formallm1/logs/cron.log

# 查看 Git 提交历史
cd /var/www/formallm1
git log --oneline -5

# 查看最新数据更新时间
cat assets/data/leaderboard.json | python3 -c "import json, sys; print(json.load(sys.stdin)['lastUpdated'])"
```

### 2. 检查 GitHub 仓库

访问：`https://github.com/your-username/alailab/commits/main`

应该能看到自动提交记录：
- 提交信息：`chore: update leaderboard and problems - 2025-11-06 ...`
- 提交者：`Leaderboard Bot`

### 3. 检查 GitHub Pages

访问您的网站：
- 排行榜页面：查看数据是否更新
- 下载页面：查看新的赛题文件是否出现

## 🔄 工作流程说明

### 完整的自动化流程

```
每天 2:00 和 14:00
    ↓
Cron 触发脚本
    ↓
auto_update.sh 执行
    ↓
1. git pull（拉取最新代码）
    ↓
2. fetch_leaderboard.py（获取排行榜）
    ↓
3. fetch_problems.py（获取赛题文件）
    ↓
4. 更新 leaderboard.json
    ↓
5. 保存 lean_MMDD.jsonl
    ↓
6. 保存 litex_MMDD.jsonl
    ↓
7. 更新 downloads.json
    ↓
8. git add + commit + push
    ↓
GitHub 收到推送
    ↓
GitHub Pages 自动部署
    ↓
用户看到最新数据
```

## 🛠️ API 端点说明

您需要确认以下 API 端点是否可用：

### 排行榜 API（已实现）
```
GET http://121.43.230.124/ranking_list/daily
参数:
  - stage: preliminary/practice
  - dt: YYYY-MM-DD

GET http://121.43.230.124/ranking_list/overall
参数:
  - stage: preliminary/practice

Header:
  X-API-Key: YOUR_API_KEY
```

### 赛题 API（需要确认）
```
GET http://121.43.230.124/problems/daily
参数:
  - date: YYYY-MM-DD
  - track: lean/litex

Header:
  X-API-Key: YOUR_API_KEY
```

⚠️ **如果您的赛题 API 端点不同，需要修改 `fetch_problems.py` 中的 URL。**

## 📝 维护和监控

### 查看日志

```bash
# 实时查看 Cron 日志
tail -f /var/www/formallm1/logs/cron.log

# 查看今天的详细日志
tail -f /var/www/formallm1/logs/update_$(date +%Y%m%d).log

# 查看最近 50 行日志
tail -50 /var/www/formallm1/logs/cron.log
```

### 手动触发更新

```bash
# 进入项目目录
cd /var/www/formallm1

# 手动执行更新
bash server/auto_update.sh YOUR_API_KEY preliminary

# 查看结果
git log -1
```

### 修改更新频率

```bash
# 编辑定时任务
crontab -e

# 修改时间表达式后保存
```

### 清理旧日志

```bash
# 清理 30 天前的日志
find /var/www/formallm1/logs -name "*.log" -mtime +30 -delete
```

## ⚠️ 常见问题

### 问题 1: 推送失败 "Permission denied"

**原因**: Deploy Key 没有写权限

**解决**:
1. 进入 GitHub 仓库 Settings → Deploy keys
2. 找到您的 Deploy Key
3. 确保勾选了 `Allow write access` ✅

### 问题 2: API 请求失败

**测试命令**:
```bash
# 测试排行榜 API
curl -H "X-API-Key: YOUR_API_KEY" \
  "http://121.43.230.124/ranking_list/overall?stage=practice"

# 测试赛题 API
curl -H "X-API-Key: YOUR_API_KEY" \
  "http://121.43.230.124/problems/daily?date=2025-11-06&track=lean"
```

### 问题 3: Git 冲突

**解决**:
```bash
cd /var/www/formallm1

# 查看状态
git status

# 如果有冲突，重置到远程版本
git fetch origin
git reset --hard origin/main

# 重新执行更新
bash server/auto_update.sh YOUR_API_KEY preliminary
```

### 问题 4: 定时任务未执行

**检查**:
```bash
# 检查 Cron 服务
sudo systemctl status cron

# 启动 Cron
sudo systemctl start cron

# 查看定时任务
crontab -l

# 查看系统日志
sudo grep CRON /var/log/syslog | tail -20
```

## 🔒 安全建议

1. **不要在代码中硬编码 API Key**
   - ✅ 通过命令行参数传递
   - ✅ 或使用环境变量

2. **保护 SSH 密钥**
   ```bash
   chmod 600 ~/.ssh/formallm_deploy
   chmod 644 ~/.ssh/formallm_deploy.pub
   ```

3. **限制文件权限**
   ```bash
   chmod 600 ~/.git-credentials  # 如果使用 Token
   ```

4. **定期轮换密钥**
   - API Key: 每 3-6 个月更换
   - GitHub Token/Deploy Key: 每 6-12 个月更换

## 📦 文件清单

### 服务器脚本
- `server/fetch_leaderboard.py` - 获取排行榜数据
- `server/fetch_problems.py` - 获取每日赛题 ⭐ 新增
- `server/auto_update.sh` - 自动更新主脚本 ⭐ 已增强
- `server/config.example.sh` - 配置示例

### 数据文件（自动生成）
- `assets/data/leaderboard.json` - 排行榜数据
- `assets/data/downloads.json` - 下载配置（自动更新）
- `assets/files/lean_MMDD.jsonl` - Lean 每日赛题
- `assets/files/litex_MMDD.jsonl` - Litex 每日赛题

## 🎯 部署后的效果

### 自动化实现的功能

✅ **排行榜自动更新**
- 每天定时从 API 获取最新排行榜
- 包含"每日榜"和"总榜"数据
- 自动推送到 GitHub
- GitHub Pages 自动部署

✅ **赛题自动发布**
- 每天定时从 API 获取新赛题
- 自动保存为 `lean_MMDD.jsonl` 和 `litex_MMDD.jsonl`
- 自动更新 `downloads.json` 配置
- 自动计算文件 MD5
- 下载页面自动显示新赛题

✅ **完全无人值守**
- 无需手动操作
- 自动记录日志
- 失败时保留旧数据

## 📞 需要帮助？

### 检查清单

- [ ] 云服务器已登录
- [ ] 仓库已克隆到 `/var/www/formallm1`
- [ ] Python 依赖已安装
- [ ] GitHub 推送权限已配置（Deploy Key 或 Token）
- [ ] Cron 定时任务已配置
- [ ] 手动测试成功
- [ ] GitHub 仓库有自动提交记录
- [ ] GitHub Pages 显示最新数据

### 测试命令汇总

```bash
# 1. 测试 API 连接
curl -H "X-API-Key: YOUR_KEY" "http://121.43.230.124/ranking_list/overall?stage=practice"

# 2. 测试 GitHub SSH
ssh -T git@github.com

# 3. 测试数据获取
cd /var/www/formallm1
python3 server/fetch_leaderboard.py YOUR_API_KEY preliminary

# 4. 测试完整流程
bash server/auto_update.sh YOUR_API_KEY preliminary

# 5. 查看定时任务
crontab -l

# 6. 查看日志
tail -f logs/cron.log
```

## 🎉 完成！

部署完成后，系统将自动：
- 每天定时更新排行榜
- 每天定时发布新赛题
- 自动推送到 GitHub
- 自动部署到 GitHub Pages

**下一步**：监控几天，确保定时任务正常运行。

---

**创建日期**: 2025-11-06  
**适用版本**: formallm1 v1.0+


