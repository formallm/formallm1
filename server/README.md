# 云服务器自动更新排行榜

本目录包含在云服务器上自动获取排行榜数据并推送到 GitHub 的脚本。

## 📁 文件说明

```
server/
├── fetch_leaderboard.py   # Python 脚本：从 API 获取排行榜数据
├── auto_update.sh         # Shell 脚本：自动更新并推送到 GitHub
├── setup.sh              # 环境配置脚本（一键安装）
├── requirements.txt      # Python 依赖
└── README.md            # 本文档
```

## 🚀 快速开始

### 方式一：一键配置（推荐）

```bash
# 1. SSH 登录到云服务器
ssh user@your-server-ip

# 2. 克隆仓库
cd /var/www
git clone https://github.com/your-username/alailab.git
cd alailab

# 3. 运行配置脚本（会自动安装依赖和配置定时任务）
bash server/setup.sh
```

按照提示输入：
- GitHub 用户名和邮箱
- GitHub Personal Access Token
- API Key
- 比赛阶段
- 更新频率

### 方式二：手动配置

#### 1. 安装依赖

```bash
# 安装系统依赖
sudo apt-get update
sudo apt-get install -y python3 python3-pip git

# 安装 Python 依赖
pip3 install -r server/requirements.txt
```

#### 2. 配置 Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

#### 3. 配置 GitHub Token

访问 https://github.com/settings/tokens 生成 Personal Access Token：
- 权限：选择 `repo` (完整仓库访问权限)

```bash
# 配置 Git 凭据存储
git config --global credential.helper store
echo "https://YOUR_TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

#### 4. 测试脚本

```bash
# 测试数据获取
python3 server/fetch_leaderboard.py your_api_key preliminary

# 检查生成的文件
cat assets/data/leaderboard.json
```

#### 5. 设置定时任务

```bash
# 编辑 crontab
crontab -e

# 添加以下内容（每天 8:00 和 20:00 更新）
0 8,20 * * * cd /var/www/alailab && /var/www/alailab/server/auto_update.sh your_api_key preliminary >> /var/www/alailab/logs/cron.log 2>&1
```

## 📖 详细说明

### fetch_leaderboard.py

从 FormaLLM 竞赛 API 获取排行榜数据。

**使用方法：**
```bash
python3 fetch_leaderboard.py [API_KEY] [STAGE]
```

**参数：**
- `API_KEY`（可选）：API 访问密钥，默认 `default_api_key`
- `STAGE`（可选）：比赛阶段，`preliminary`（初赛）或 `practice`（练习赛），默认 `preliminary`

**示例：**
```bash
# 使用默认参数
python3 server/fetch_leaderboard.py

# 指定 API Key
python3 server/fetch_leaderboard.py my_api_key

# 指定 API Key 和阶段
python3 server/fetch_leaderboard.py my_api_key practice
```

**输出文件：**
- `assets/data/leaderboard.json` - 前端所需的排行榜数据

### auto_update.sh

自动执行完整的更新流程：拉取代码 → 获取数据 → 提交 → 推送。

**使用方法：**
```bash
bash server/auto_update.sh [API_KEY] [STAGE]
```

**功能：**
1. 拉取最新代码（避免冲突）
2. 执行 `fetch_leaderboard.py` 获取数据
3. 检查数据是否有变化
4. 如有变化，自动提交并推送到 GitHub
5. 记录日志到 `logs/` 目录

**日志文件：**
- `logs/update_YYYYMMDD.log` - 每日更新日志
- `logs/cron.log` - Cron 任务日志

## ⏰ Cron 定时任务示例

```bash
# 每小时更新
0 * * * * cd /var/www/alailab && ./server/auto_update.sh your_api_key preliminary >> logs/cron.log 2>&1

# 每 6 小时更新
0 */6 * * * cd /var/www/alailab && ./server/auto_update.sh your_api_key preliminary >> logs/cron.log 2>&1

# 每天 8:00 更新
0 8 * * * cd /var/www/alailab && ./server/auto_update.sh your_api_key preliminary >> logs/cron.log 2>&1

# 每天 8:00 和 20:00 更新（推荐）
0 8,20 * * * cd /var/www/alailab && ./server/auto_update.sh your_api_key preliminary >> logs/cron.log 2>&1

# 每 30 分钟更新（比赛期间）
*/30 * * * * cd /var/www/alailab && ./server/auto_update.sh your_api_key preliminary >> logs/cron.log 2>&1
```

## 🔍 查看运行状态

```bash
# 查看定时任务
crontab -l

# 查看最新日志
tail -f logs/cron.log

# 查看今日更新日志
tail -f logs/update_$(date +%Y%m%d).log

# 查看 Git 提交历史
git log --oneline -10

# 检查最新数据
cat assets/data/leaderboard.json | python3 -m json.tool
```

## 🐛 故障排查

### 问题 1：推送失败 "Authentication failed"

**原因：** GitHub Token 配置不正确

**解决：**
```bash
# 重新配置凭据
rm ~/.git-credentials
git config --global credential.helper store
echo "https://YOUR_NEW_TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
```

### 问题 2：API 请求失败

**原因：** API Key 无效或网络问题

**解决：**
```bash
# 测试 API 连接
curl -H "X-API-Key: your_api_key" "http://121.43.230.124/ranking_list/daily?stage=preliminary&dt=2025-10-30"

# 检查网络
ping 121.43.230.124
```

### 问题 3：定时任务未执行

**原因：** Cron 服务未启动或路径配置错误

**解决：**
```bash
# 检查 Cron 服务状态
sudo systemctl status cron    # Ubuntu/Debian
sudo systemctl status crond   # CentOS/RHEL

# 启动 Cron 服务
sudo systemctl start cron

# 检查定时任务
crontab -l

# 手动执行测试
bash server/auto_update.sh your_api_key preliminary
```

### 问题 4：Python 模块找不到

**原因：** 依赖未正确安装

**解决：**
```bash
# 重新安装依赖
pip3 install --user -r server/requirements.txt

# 或使用系统 pip
sudo pip3 install -r server/requirements.txt
```

## 📊 监控和通知（可选）

### 添加邮件通知

在 `auto_update.sh` 末尾添加：

```bash
# 发送邮件通知（需要配置 mailutils）
echo "排行榜更新完成 $(date)" | mail -s "排行榜更新成功" your-email@example.com
```

### 添加企业微信/钉钉通知

```python
# 在 fetch_leaderboard.py 中添加
import requests

def send_wechat_notification(message):
    webhook = "your_webhook_url"
    data = {
        "msgtype": "text",
        "text": {"content": message}
    }
    requests.post(webhook, json=data)
```

## 🔒 安全建议

1. **不要在代码中硬编码敏感信息**
   - 使用环境变量或配置文件
   - 将 API Key 通过命令行参数传递

2. **保护凭据文件**
   ```bash
   chmod 600 ~/.git-credentials
   ```

3. **使用只读 Token（如果可能）**
   - GitHub Token 只授予必要的权限

4. **定期轮换密钥**
   - 每 3-6 个月更换 API Key 和 GitHub Token

## 📝 维护建议

- 定期检查日志文件大小，必要时清理旧日志
- 监控 GitHub Actions 状态
- 在比赛期间增加更新频率
- 在比赛结束后降低更新频率或停止定时任务

## 🤝 贡献

如有问题或改进建议，请提交 Issue 或 Pull Request。

