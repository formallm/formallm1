# ForMaLLM 竞赛网站使用指南

## 📚 目录

- [概览](#概览)
- [访问网站](#访问网站)
- [管理员指南](#管理员指南)
- [开发者指南](#开发者指南)
- [常见问题](#常见问题)

## 概览

ForMaLLM 竞赛网站由以下部分组成：

1. **静态网站** - 托管在 GitHub Pages
2. **排行榜数据** - 从 API 自动获取并更新
3. **自动化脚本** - 在云服务器或 GitHub Actions 上运行

### 系统架构

```
用户 → GitHub Pages → leaderboard.json
                         ↑
                    自动更新
                         ↑
        云服务器/GitHub Actions
                         ↑
                    ForMaLLM API
```

## 访问网站

### 公开访问地址

- **中文版首页**: `https://your-username.github.io/alailab/cn/`
- **英文版首页**: `https://your-username.github.io/alailab/en/`
- **排行榜**: `https://your-username.github.io/alailab/cn/leaderboard.html`

### 页面导航

**中文版：**
- `/cn/index.html` - 首页
- `/cn/about.html` - 关于竞赛
- `/cn/downloads.html` - 赛题下载
- `/cn/leaderboard.html` - 实时排行榜

**英文版：**
- `/en/index.html` - Home
- `/en/about.html` - About
- `/en/downloads.html` - Downloads
- `/en/leaderboard.html` - Leaderboard

## 管理员指南

### 更新网站内容

#### 1. 修改页面文字

```bash
# 编辑对应的 HTML 文件
# 例如修改关于页面
nano cn/about.html

# 提交更改
git add cn/about.html
git commit -m "Update about page"
git push
```

#### 2. 更新样式

```bash
# 编辑 CSS 文件
nano assets/css/style.css

# 提交更改
git add assets/css/style.css
git commit -m "Update styles"
git push
```

#### 3. 添加新页面

```bash
# 1. 创建新的 HTML 文件
cp cn/about.html cn/new-page.html

# 2. 编辑内容
nano cn/new-page.html

# 3. 在导航栏中添加链接（编辑所有相关页面）
# 在 <nav> 中添加：
# <li><a href="new-page.html">新页面</a></li>

# 4. 提交
git add cn/new-page.html
git commit -m "Add new page"
git push
```

### 管理排行榜数据

#### 方式 1：通过云服务器自动更新

**查看状态：**
```bash
# SSH 登录到云服务器
ssh your-user@your-server-ip

# 查看最新日志
tail -f /var/www/alailab/logs/cron.log

# 查看定时任务
crontab -l
```

**手动触发更新：**
```bash
cd /var/www/alailab
bash server/auto_update.sh your_api_key preliminary
```

**修改更新频率：**
```bash
# 编辑定时任务
crontab -e

# 修改为您需要的频率，例如每小时：
# 0 * * * * cd /var/www/alailab && ./server/auto_update.sh your_api_key preliminary >> logs/cron.log 2>&1
```

#### 方式 2：通过 GitHub Actions 自动更新

**手动触发：**
1. 访问 `https://github.com/your-username/alailab/actions`
2. 选择 "Update Leaderboard" 工作流
3. 点击 "Run workflow"
4. 选择比赛阶段
5. 点击 "Run workflow"

**查看执行历史：**
1. 访问 Actions 标签页
2. 查看工作流运行记录
3. 点击具体记录查看详细日志

**修改 API Key：**
1. 进入仓库 Settings → Secrets and variables → Actions
2. 编辑 `FORMALLM_API_KEY`
3. 更新为新的 API Key

#### 方式 3：手动更新数据

```bash
# 1. 本地获取数据
cd /path/to/alailab
python3 server/fetch_leaderboard.py your_api_key preliminary

# 2. 检查生成的文件
cat assets/data/leaderboard.json

# 3. 提交并推送
git add assets/data/leaderboard.json
git commit -m "Update leaderboard data manually"
git push
```

### 监控和维护

#### 检查网站状态

```bash
# 1. 访问网站确认可访问
curl -I https://your-username.github.io/alailab/

# 2. 检查排行榜数据
curl https://your-username.github.io/alailab/assets/data/leaderboard.json

# 3. 验证 JSON 格式
curl -s https://your-username.github.io/alailab/assets/data/leaderboard.json | python3 -m json.tool
```

#### 日志管理

```bash
# 查看服务器日志
cd /var/www/alailab

# 实时日志
tail -f logs/cron.log

# 今日更新日志
cat logs/update_$(date +%Y%m%d).log

# 清理旧日志（保留最近 30 天）
find logs/ -name "*.log" -mtime +30 -delete
```

#### 备份

```bash
# 定期备份关键文件
tar -czf backup_$(date +%Y%m%d).tar.gz \
  cn/ \
  en/ \
  assets/ \
  server/ \
  *.md

# 上传到备份服务器或云存储
scp backup_*.tar.gz backup-server:/backups/
```

## 开发者指南

### 本地开发环境

#### 1. 克隆仓库

```bash
git clone https://github.com/your-username/alailab.git
cd alailab
```

#### 2. 启动本地服务器

```bash
# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000

# 或使用 Node.js
npx http-server -p 8000
```

#### 3. 访问网站

打开浏览器访问：
- `http://localhost:8000/cn/` - 中文版
- `http://localhost:8000/en/` - 英文版

### 测试排行榜功能

#### 1. 生成测试数据

```bash
# 使用真实 API
python3 server/fetch_leaderboard.py your_api_key preliminary

# 或创建模拟数据
cat > assets/data/leaderboard.json << 'EOF'
{
  "lastUpdated": "2025-10-30T08:00:00+08:00",
  "stage": "preliminary",
  "litex": {
    "daily": [
      {"rank": 1, "teamName": "Test Team 1", "teamId": "001", "score": 95.0}
    ],
    "overall": [
      {"rank": 1, "teamName": "Test Team 1", "teamId": "001", "score": 95.0}
    ]
  },
  "lean": {
    "daily": [
      {"rank": 1, "teamName": "Test Team 2", "teamId": "002", "score": 92.0}
    ],
    "overall": [
      {"rank": 1, "teamName": "Test Team 2", "teamId": "002", "score": 92.0}
    ]
  }
}
EOF
```

#### 2. 在浏览器中测试

1. 访问 `http://localhost:8000/cn/leaderboard.html`
2. 打开开发者工具（F12）
3. 在 Console 中执行：
   ```javascript
   // 查看加载的数据
   console.log(LeaderboardAPI.cache);
   
   // 强制刷新数据
   LeaderboardAPI.refresh();
   ```

### 代码结构

#### JavaScript 模块

**`assets/js/main.js`** - 主脚本
- 主题切换
- 导航菜单
- 滚动效果
- 表单验证

**`assets/js/leaderboard.js`** - 排行榜脚本
- 数据获取
- 表格渲染
- 切换功能

#### CSS 组件

**`assets/css/style.css`** - 样式表
- 变量定义（`:root`）
- 基础样式
- 组件样式
- 响应式设计

### 自定义样式

#### 修改主题颜色

编辑 `assets/css/style.css`：

```css
:root {
  /* 主色调 */
  --primary: #1a73e8;      /* 修改主色 */
  --primary-dark: #1557b0;
  --primary-light: #4285f4;
  
  /* 其他颜色 */
  --accent: #ff6b35;       /* 修改强调色 */
  /* ... */
}
```

#### 添加新组件

```css
/* 在 style.css 末尾添加 */
.custom-component {
  /* 样式规则 */
}
```

### API 集成

#### 使用排行榜 API

```javascript
// 获取数据
const response = await fetch('/assets/data/leaderboard.json');
const data = await response.json();

// 访问 Litex 今日榜
const litexDaily = data.litex.daily;

// 访问 Lean 总榜
const leanOverall = data.lean.overall;
```

#### 添加新的数据源

修改 `server/fetch_leaderboard.py`：

```python
def fetch_custom_data():
    """获取自定义数据"""
    url = "https://your-api.com/endpoint"
    response = requests.get(url)
    return response.json()
```

## 常见问题

### Q1: 排行榜数据不更新怎么办？

**A:** 按以下步骤排查：
1. 检查云服务器 Cron 任务是否正常运行
2. 查看日志文件 `logs/cron.log`
3. 手动执行更新脚本测试
4. 检查 API Key 是否有效
5. 验证网络连接

### Q2: 网站显示 404 错误？

**A:** 可能的原因：
1. GitHub Pages 未启用 - 在仓库设置中启用
2. 路径错误 - 确认访问正确的 URL
3. 构建失败 - 查看 Actions 标签页

### Q3: 如何更改更新频率？

**A:** 
- **云服务器**: 编辑 crontab (`crontab -e`)
- **GitHub Actions**: 编辑 `.github/workflows/update-leaderboard.yml`

### Q4: 可以使用自定义域名吗？

**A:** 可以！步骤：
1. 在域名 DNS 中添加 CNAME 记录
2. 在 GitHub Pages 设置中配置自定义域名
3. 在仓库根目录添加 `CNAME` 文件

### Q5: 如何备份数据？

**A:** 
```bash
# 自动备份（添加到 crontab）
0 2 * * * cd /var/www/alailab && tar -czf backup_$(date +\%Y\%m\%d).tar.gz . && mv backup_*.tar.gz /backup/
```

### Q6: 支持多少用户同时访问？

**A:** GitHub Pages 可以处理大量并发访问，通常不会有性能问题。如需更高性能，可以考虑：
- 启用 CDN (Cloudflare)
- 优化图片和资源
- 使用浏览器缓存

### Q7: 如何添加新语言版本？

**A:** 
1. 复制 `cn/` 目录为新语言代码（如 `ja/` 日语）
2. 翻译所有文本内容
3. 更新导航栏中的语言切换链接
4. 添加 `hreflang` 标签用于 SEO

### Q8: 如何限制 API 访问频率？

**A:** 在 `server/fetch_leaderboard.py` 中添加：
```python
import time

# 在请求前添加延迟
time.sleep(1)  # 延迟 1 秒
```

## 📞 获取帮助

- 📖 查看 [部署指南](../DEPLOYMENT.md)
- 📗 查看 [服务器脚本文档](../server/README.md)
- 🐛 提交 [Issue](https://github.com/your-username/alailab/issues)
- 📧 联系管理员

---

**最后更新**: 2025-10-30

