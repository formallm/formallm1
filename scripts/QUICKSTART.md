# 快速开始：5分钟配置自动更新

## 一键部署命令

在您的云服务器上依次执行以下命令：

```bash
# 1. 进入网站目录
cd /var/www/formsci

# 2. 设置脚本执行权限
chmod +x scripts/*.sh

# 3. 配置GitHub SSH（需要手动添加Deploy Key到GitHub）
bash scripts/setup-github.sh

# 4. 配置定时任务
bash scripts/setup-cron.sh

# 5. 测试一次手动更新
bash scripts/manual-update.sh
```

## 详细步骤

### 步骤1：上传代码到服务器

**方式A：Git克隆（推荐）**

```bash
cd /var/www
git clone git@github.com:your-username/alailab.git formsci
```

**方式B：从本地上传**

```bash
# 在本地执行（Windows PowerShell）
scp -r D:\HuaweiMoveData\Users\NERV\Desktop\alailab ubuntu@121.43.230.124:/var/www/formsci
```

### 步骤2：安装依赖

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y git curl jq

# 验证安装
git --version
curl --version
jq --version
```

### 步骤3：配置API地址

编辑 `scripts/update-data.sh`：

```bash
nano scripts/update-data.sh
```

修改以下行（第12-13行）：

```bash
# 确认API地址正确
LEADERBOARD_API="http://121.43.230.124/results/leaderboard"
PROBLEMS_API="http://121.43.230.124/results/daily/{{DATE}}"
```

保存并退出（`Ctrl+O`, `Enter`, `Ctrl+X`）

### 步骤4：配置GitHub

```bash
bash scripts/setup-github.sh
```

按照提示操作：

1. 脚本会生成SSH密钥
2. **复制显示的公钥**
3. 打开 GitHub 仓库页面
4. 进入 **Settings** → **Deploy keys** → **Add deploy key**
5. 标题填写：`Auto Update Bot`
6. 粘贴公钥
7. **必须勾选** `Allow write access` ✓
8. 点击 **Add key**
9. 回到终端，按 Enter 继续

测试连接：

```bash
ssh -T git@github.com
# 应该看到：Hi xxx! You've successfully authenticated...
```

### 步骤5：测试手动更新

```bash
bash scripts/manual-update.sh
```

检查输出是否显示：
- ✓ 排行榜数据下载成功
- ✓ 赛题数据下载成功（如果有）
- ✓ 提交成功
- ✓ 推送成功到 GitHub

查看日志：

```bash
tail -20 /var/log/formsci-update/update-$(date +%Y%m%d).log
```

### 步骤6：配置自动更新

```bash
bash scripts/setup-cron.sh
```

查看定时任务：

```bash
crontab -l
```

应该看到：

```
# 自动更新排行榜和赛题数据
0 1,13 * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1
```

## 验证部署

### 1. 检查GitHub仓库

访问您的GitHub仓库，应该能看到最新的提交：
- 提交信息：`Auto update: leaderboard and problems data at ...`
- 修改文件：`assets/data/leaderboard.json`

### 2. 检查GitHub Pages

访问您的GitHub Pages网站：
- `https://your-username.github.io/alailab/`
- 点击 **排行榜** 菜单
- 应该显示最新的排名数据

### 3. 测试定时任务

不用等到凌晨1点，可以立即测试：

```bash
# 临时添加一个1分钟后执行的任务
(crontab -l; echo "$(date -d '+1 minute' +'%M %H') * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1") | crontab -

# 等待1-2分钟后检查日志
tail -f /var/log/formsci-update/cron.log
```

测试完成后移除临时任务：

```bash
crontab -e
# 删除刚才添加的那一行，保存退出
```

## 常见问题

### Q1: GitHub推送失败，提示 `Permission denied`

**原因**：Deploy Key没有写权限

**解决**：
1. 打开 GitHub → Settings → Deploy keys
2. 找到 `Auto Update Bot`
3. 点击编辑
4. **勾选** `Allow write access`
5. 保存

### Q2: 数据下载失败

**原因**：服务器IP不在白名单或API地址错误

**测试命令**：

```bash
curl -v http://121.43.230.124/results/leaderboard
```

如果返回403或连接失败，请联系管理员添加服务器IP到白名单。

### Q3: 定时任务不执行

**排查步骤**：

```bash
# 1. 检查cron服务
sudo systemctl status cron

# 2. 手动执行看是否有错误
bash /var/www/formsci/scripts/update-data.sh

# 3. 检查脚本权限
ls -l /var/www/formsci/scripts/update-data.sh
# 应该显示 -rwxr-xr-x

# 4. 确保使用绝对路径
crontab -l
```

### Q4: JSON格式错误

**原因**：API返回的数据格式不正确

**检查方法**：

```bash
# 下载数据并验证格式
curl http://121.43.230.124/results/leaderboard | jq .

# 如果看到 "parse error"，说明格式有问题
```

请联系后端开发人员修复API返回格式。

## 修改定时任务频率

如需修改更新频率：

```bash
crontab -e
```

示例：

```bash
# 每小时更新一次
0 * * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1

# 每6小时更新一次（0点、6点、12点、18点）
0 0,6,12,18 * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1

# 仅每天凌晨3点更新
0 3 * * * /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1

# 工作日每天9点和18点更新
0 9,18 * * 1-5 /var/www/formsci/scripts/update-data.sh >> /var/log/formsci-update/cron.log 2>&1
```

## 监控命令

```bash
# 查看今天的更新日志
tail -f /var/log/formsci-update/update-$(date +%Y%m%d).log

# 查看cron执行日志
tail -f /var/log/formsci-update/cron.log

# 查看最近的Git提交
cd /var/www/formsci && git log --oneline -10

# 查看当前数据更新时间
cd /var/www/formsci && cat assets/data/leaderboard.json | jq .lastUpdated
```

## 下一步

配置完成后：

1. ✓ 数据每天自动更新（凌晨1点和下午1点）
2. ✓ 自动推送到GitHub
3. ✓ GitHub Pages自动部署更新
4. ✓ 用户访问网站看到最新数据

如需进一步优化，请参考 `DEPLOY_GUIDE.md` 的高级配置章节。

