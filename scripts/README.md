# 自动更新脚本说明

本目录包含用于自动更新排行榜和赛题数据的脚本。

## 📁 文件列表

| 文件 | 说明 |
|------|------|
| `update-data.sh` | 主更新脚本：拉取数据、验证、推送到GitHub |
| `setup-github.sh` | GitHub SSH配置脚本 |
| `setup-cron.sh` | 定时任务配置脚本 |
| `manual-update.sh` | 手动触发更新（用于测试） |
| `QUICKSTART.md` | 5分钟快速开始指南 ⭐ |

## 🚀 快速开始

### 首次部署

```bash
# 1. 上传代码到服务器
cd /var/www/formsci

# 2. 设置执行权限
chmod +x scripts/*.sh

# 3. 配置GitHub（需要添加Deploy Key）
bash scripts/setup-github.sh

# 4. 配置定时任务
bash scripts/setup-cron.sh

# 5. 测试更新
bash scripts/manual-update.sh
```

**详细步骤请查看：[QUICKSTART.md](./QUICKSTART.md)** ⭐

## 📖 完整文档

完整的部署指南请查看：[../DEPLOY_GUIDE.md](../DEPLOY_GUIDE.md)

内容包括：
- 详细的部署步骤
- API数据格式说明
- 监控和维护方法
- 故障排查指南
- 安全建议
- 高级配置选项

## 🔧 脚本功能

### update-data.sh

主要功能：
- 从白名单服务器获取排行榜数据
- 从白名单服务器获取每日赛题数据
- 验证JSON格式
- 自动提交并推送到GitHub
- 完整的日志记录

配置项：
```bash
LEADERBOARD_API="http://121.43.230.124/results/leaderboard"
PROBLEMS_API="http://121.43.230.124/results/daily/{{DATE}}"
REPO_DIR="/var/www/formsci"
GIT_BRANCH="main"
```

### setup-github.sh

功能：
- 生成SSH密钥
- 配置Git用户信息
- 测试GitHub连接
- 初始化Git仓库

### setup-cron.sh

功能：
- 配置定时任务（每天凌晨1点和下午1点）
- 创建日志目录
- 备份现有crontab

### manual-update.sh

功能：
- 手动触发一次数据更新
- 用于测试和调试

## 📊 数据流程

```
┌─────────────────────────┐
│  白名单服务器            │
│  121.43.230.124         │
│  - 排行榜API            │
│  - 每日赛题API          │
└───────────┬─────────────┘
            │ HTTP请求
            ↓
┌─────────────────────────┐
│  云服务器                │
│  - cron定时任务         │
│  - update-data.sh       │
│  - 数据验证与处理       │
└───────────┬─────────────┘
            │ Git Push
            ↓
┌─────────────────────────┐
│  GitHub仓库              │
│  - 自动触发Actions      │
│  - 部署到Pages          │
└───────────┬─────────────┘
            │ 自动部署
            ↓
┌─────────────────────────┐
│  GitHub Pages           │
│  - 静态网站              │
│  - 用户访问              │
└─────────────────────────┘
```

## 🕐 定时任务

默认配置：
```cron
0 1,13 * * * /var/www/formsci/scripts/update-data.sh
```

执行时间：
- 每天 **01:00**（凌晨1点）
- 每天 **13:00**（下午1点）

修改频率：
```bash
crontab -e

# 示例：每小时执行
0 * * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1

# 示例：每6小时执行
0 */6 * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1
```

## 📝 日志位置

```
/var/log/formsci-update/
├── update-20251030.log   # 每日详细日志
├── update-20251031.log
└── cron.log               # Cron执行日志
```

查看日志：
```bash
# 查看今天的日志
tail -f /var/log/formsci-update/update-$(date +%Y%m%d).log

# 查看cron日志
tail -f /var/log/formsci-update/cron.log

# 查看所有日志文件
ls -lh /var/log/formsci-update/
```

## ✅ 验证部署

### 1. 检查定时任务
```bash
crontab -l
```

### 2. 手动测试
```bash
bash scripts/manual-update.sh
```

### 3. 查看GitHub提交
```bash
cd /var/www/formsci
git log --oneline -5
```

### 4. 访问网站
打开浏览器访问：`https://your-username.github.io/alailab/leaderboard.html`

## 🐛 故障排查

### 推送失败

```bash
# 测试SSH连接
ssh -T git@github.com

# 检查Deploy Key权限
# GitHub → Settings → Deploy keys → 确保勾选 "Allow write access"
```

### 数据下载失败

```bash
# 测试API连接
curl -v http://121.43.230.124/results/leaderboard

# 检查服务器IP是否在白名单
```

### JSON验证失败

```bash
# 检查JSON格式
curl http://121.43.230.124/results/leaderboard | jq .
```

### 定时任务不执行

```bash
# 检查cron服务
sudo systemctl status cron

# 检查脚本权限
ls -l scripts/update-data.sh

# 查看cron日志
tail -f /var/log/formsci-update/cron.log
```

## 🔒 安全提示

1. ✓ SSH密钥只用于此仓库的Deploy Key
2. ✓ 定期检查日志，监控异常推送
3. ✓ 限制API访问，使用IP白名单
4. ✓ 定期更新系统依赖（git、curl、jq）

## 📞 获取帮助

遇到问题请检查：
1. [QUICKSTART.md](./QUICKSTART.md) - 快速开始指南
2. [../DEPLOY_GUIDE.md](../DEPLOY_GUIDE.md) - 完整部署指南
3. `/var/log/formsci-update/` - 日志文件
4. GitHub仓库的Issues页面

## 📄 许可

本脚本集为项目内部使用，请勿用于其他用途。

