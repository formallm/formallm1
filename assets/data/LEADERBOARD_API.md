# 排行榜数据接入说明

## 数据接口

排行榜系统支持动态数据加载，可通过以下方式更新数据：

### 1. JSON 文件更新（推荐）

直接更新 `assets/data/leaderboard.json` 文件即可，系统会自动加载最新数据。

**数据格式：**

```json
{
  "lastUpdated": "2025-10-30T08:00:00+08:00",
  "daily": [
    {
      "rank": 1,
      "teamName": "队伍名称",
      "members": "成员名单",
      "score": 87.00000000,
      "submitTime": "2025-10-25 11:46",
      "submissionCount": 2
    }
  ],
  "overall": [
    {
      "rank": 1,
      "teamName": "队伍名称",
      "members": "成员名单",
      "score": 87.00000000,
      "submitTime": "2025-10-25 11:46",
      "submissionCount": 2
    }
  ]
}
```

**字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `lastUpdated` | string | 数据更新时间（ISO 8601 格式） |
| `rank` | number | 排名 |
| `teamName` | string | 队伍名称 |
| `members` | string | 成员名单（用空格分隔） |
| `score` | number | 得分 |
| `submitTime` | string | 提交时间（YYYY-MM-DD HH:mm 格式） |
| `submissionCount` | number | 有效提交次数 |

### 2. 云端API接入

如需从云端API动态获取数据，可修改 `assets/js/leaderboard.js` 中的 `dataURL` 配置：

```javascript
const LeaderboardAPI = {
  // 修改为您的API地址
  dataURL: 'https://your-api-endpoint.com/leaderboard.json',
  // ...
};
```

API 返回的 JSON 格式应与上述格式一致。

### 3. 手动注入数据

可通过浏览器控制台直接注入数据（用于测试）：

```javascript
// 在排行榜页面打开浏览器控制台，执行：
LeaderboardAPI.set({
  lastUpdated: "2025-10-30T08:00:00+08:00",
  daily: [...],
  overall: [...]
});
```

### 4. 强制刷新

如需强制刷新排行榜数据（清除缓存）：

```javascript
// 在浏览器控制台执行：
LeaderboardAPI.refresh();
```

## 自动化部署

### 使用 GitHub Actions 自动更新

在 `.github/workflows/update-leaderboard.yml` 中配置定时任务：

```yaml
name: Update Leaderboard

on:
  schedule:
    - cron: '0 0 * * *'  # 每天 00:00 UTC 更新
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Fetch latest data
        run: |
          curl -o assets/data/leaderboard.json \
            https://your-source-api.com/leaderboard
      
      - name: Commit changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add assets/data/leaderboard.json
          git commit -m "Update leaderboard data" || exit 0
          git push
```

### 使用云服务器 cron 任务

在云服务器上配置定时任务：

```bash
# 编辑 crontab
crontab -e

# 添加任务（每天凌晨1点更新）
0 1 * * * /path/to/update-leaderboard.sh
```

更新脚本示例 `update-leaderboard.sh`：

```bash
#!/bin/bash
cd /var/www/formsci

# 从源API获取数据
curl -o assets/data/leaderboard.json.tmp \
  http://121.43.230.124/results/leaderboard

# 验证JSON格式
if jq empty assets/data/leaderboard.json.tmp 2>/dev/null; then
  mv assets/data/leaderboard.json.tmp assets/data/leaderboard.json
  echo "Leaderboard updated successfully at $(date)"
else
  echo "Invalid JSON format, skipping update"
  rm assets/data/leaderboard.json.tmp
fi
```

## 本地开发

本地开发时，如果无法访问 `assets/data/leaderboard.json`（CORS限制），系统会自动回退到页面内嵌的示例数据。

可在 `leaderboard.html` 和 `en/leaderboard.html` 的 `<script id="leaderboard-data">` 标签中修改示例数据。

## 故障排查

1. **数据未显示**
   - 检查浏览器控制台是否有错误信息
   - 验证 JSON 格式是否正确（可使用 jsonlint.com）
   - 确认文件路径和权限设置

2. **数据未更新**
   - 清除浏览器缓存
   - 在控制台执行 `LeaderboardAPI.refresh()`
   - 检查 JSON 文件的 `lastUpdated` 字段

3. **排名显示异常**
   - 确认 `rank` 字段为数字类型
   - 检查数据是否按排名排序
   - 验证并列排名的处理逻辑

## 联系支持

如有问题，请联系技术支持团队。

