# ✅ 部署检查清单

使用此清单确保您的 FormaLLM 竞赛网站部署完整且正常工作。

## 📋 GitHub Pages 部署

### 基础设置

- [ ] GitHub 仓库已创建
- [ ] 代码已推送到 `main` 分支
- [ ] GitHub Pages 已在仓库设置中启用
- [ ] 网站可以通过 `https://your-username.github.io/alailab/` 访问

### 页面检查

- [ ] 首页（中文）可以正常访问
- [ ] 首页（英文）可以正常访问
- [ ] 关于页面正常显示
- [ ] 下载页面正常显示
- [ ] 排行榜页面正常显示
- [ ] 导航菜单工作正常
- [ ] 语言切换功能正常
- [ ] 主题切换（明暗模式）正常

### 功能测试

- [ ] 移动端响应式布局正常
- [ ] 所有链接可以点击
- [ ] 图片正常加载
- [ ] CSS 样式正确应用
- [ ] JavaScript 无错误（按 F12 查看 Console）

## 🤖 自动更新配置

### 选择您的自动更新方式

请选择以下其中一种方式：

#### 方式 A：云服务器 Cron（推荐企业项目）

- [ ] 云服务器已准备好（Linux）
- [ ] SSH 可以连接到服务器
- [ ] 仓库已克隆到服务器
- [ ] Python 3.7+ 已安装
- [ ] Git 已安装
- [ ] `requests` 库已安装 (`pip3 install requests`)
- [ ] 脚本权限已设置 (`chmod +x server/*.sh server/*.py`)
- [ ] GitHub Token 已配置
- [ ] Git credentials helper 已配置
- [ ] API Key 已获取
- [ ] 定时任务（Cron）已配置
- [ ] 手动测试成功 (`bash server/auto_update.sh`)
- [ ] 日志文件正常生成

验证命令：
```bash
# 在云服务器上执行
cd /var/www/alailab
python3 --version          # 检查 Python 版本
git --version              # 检查 Git 版本
crontab -l                 # 查看定时任务
bash server/auto_update.sh your_api_key preliminary  # 测试
```

#### 方式 B：GitHub Actions（推荐个人项目）

- [ ] `.github/workflows/update-leaderboard.yml` 文件已存在
- [ ] API Key 已添加到 GitHub Secrets (`FORMALLM_API_KEY`)
- [ ] 工作流已启用
- [ ] 手动触发测试成功
- [ ] 查看 Actions 日志无错误
- [ ] 数据自动提交到仓库

验证步骤：
1. 访问 `https://github.com/your-username/alailab/actions`
2. 选择 "Update Leaderboard" 工作流
3. 点击 "Run workflow" 手动触发
4. 查看执行日志是否成功

## 📊 排行榜数据

### 数据文件

- [ ] `assets/data/leaderboard.json` 文件存在
- [ ] JSON 格式正确（可用 `python3 -m json.tool` 验证）
- [ ] 包含 `litex` 和 `lean` 两个赛道数据
- [ ] 包含 `daily` 和 `overall` 数据
- [ ] `lastUpdated` 时间戳正确

### 排行榜显示

- [ ] 排行榜页面可以加载数据
- [ ] Litex 赛道数据正常显示
- [ ] Lean 赛道数据正常显示
- [ ] "今日榜" / "总榜" 切换正常
- [ ] 排名、队伍名称、分数正确显示
- [ ] 前三名有特殊标记（奖杯图标或高亮）

验证方法：
```bash
# 在浏览器按 F12 打开开发者工具，Console 中执行：
LeaderboardAPI.cache  # 查看加载的数据
```

## 🔧 配置文件

### Git 配置

- [ ] Git 用户名已配置
- [ ] Git 邮箱已配置
- [ ] GitHub Token 有效且权限正确（需要 `repo` 权限）
- [ ] 可以成功推送到仓库

验证：
```bash
git config user.name
git config user.email
git push --dry-run
```

### API 配置

- [ ] API Key 正确
- [ ] API 端点可以访问 (`http://121.43.230.124`)
- [ ] 比赛阶段参数正确（`preliminary` 或 `practice`）

验证：
```bash
curl -H "X-API-Key: your_api_key" \
  "http://121.43.230.124/ranking_list/daily?stage=preliminary&dt=$(date +%Y-%m-%d)"
```

## 📝 文档和资源

- [ ] README.md 已更新（替换 `your-username` 等占位符）
- [ ] DEPLOYMENT.md 已查阅
- [ ] 知道如何查看日志
- [ ] 知道如何手动触发更新
- [ ] 知道如何修改更新频率

## 🔒 安全检查

- [ ] API Key 未提交到 Git 仓库
- [ ] GitHub Token 未提交到 Git 仓库
- [ ] `.gitignore` 已配置正确
- [ ] 敏感配置文件已排除（`server/config.sh`, `.env`）
- [ ] 服务器 SSH 使用密钥而非密码
- [ ] 服务器防火墙已配置

## 🎯 性能和优化

- [ ] 图片已优化（大小合理）
- [ ] CSS 和 JS 文件已压缩（可选）
- [ ] 启用了浏览器缓存
- [ ] GitHub Pages 自动使用 CDN

## 📈 监控和维护

### 日志监控

- [ ] 知道如何查看更新日志
- [ ] 日志文件路径正确配置
- [ ] 定期清理旧日志的策略（可选）

### 备份

- [ ] 知道如何备份网站文件
- [ ] 知道如何恢复备份
- [ ] 考虑了自动备份策略（可选）

### 告警（可选）

- [ ] 配置了失败通知（邮件/企业微信/钉钉）
- [ ] 配置了监控告警

## 🧪 测试场景

### 端到端测试

完成以下完整流程测试：

1. **数据更新测试**
   - [ ] 触发数据更新（手动或等待定时任务）
   - [ ] 检查日志输出正常
   - [ ] 确认 `leaderboard.json` 已更新
   - [ ] 确认 Git 提交成功
   - [ ] 确认 GitHub Pages 已更新
   - [ ] 刷新浏览器看到新数据

2. **故障恢复测试**
   - [ ] API 不可用时，网站仍显示旧数据（降级处理）
   - [ ] 网络问题时，脚本正确记录错误

3. **多设备测试**
   - [ ] 在桌面浏览器测试（Chrome/Firefox/Safari）
   - [ ] 在移动设备测试（iOS/Android）
   - [ ] 在不同屏幕尺寸下测试响应式布局

## ✨ 最后检查

- [ ] 所有上述项目都已勾选 ✅
- [ ] 网站可以公开访问且工作正常
- [ ] 自动更新正常工作（等待下一次更新验证）
- [ ] 团队成员已了解如何管理网站
- [ ] 文档已保存在安全位置

## 🎉 完成！

恭喜！您已成功部署 FormaLLM 竞赛网站。

### 下一步

1. 📢 分享网站链接给用户
2. 📊 监控访问量和性能
3. 🔄 定期检查自动更新是否正常
4. 📝 记录遇到的问题和解决方案
5. 🤝 与社区分享经验

## 📞 需要帮助？

如果某些项目无法勾选，请查阅：
- 📘 [部署指南](../DEPLOYMENT.md)
- 📗 [快速开始](../QUICKSTART_SERVER.md)
- 📙 [使用指南](USAGE_GUIDE.md)
- 🐛 [提交 Issue](https://github.com/your-username/alailab/issues)

---

**提示**: 建议将此清单打印出来或保存为 TODO 列表，逐项完成。

