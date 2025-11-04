# 排行榜"今日榜"功能开关说明

## 📝 功能说明

为了便于灵活控制排行榜的显示内容，我们在排行榜系统中添加了一个配置开关，可以轻松地隐藏或显示"今日榜"功能。

当前状态：**已隐藏今日榜，仅显示总榜**

## 🔧 如何重新启用"今日榜"

如果您需要重新显示"今日榜"功能，只需按以下步骤操作：

1. 打开文件：`formallm1/assets/js/leaderboard.js`

2. 找到文件开头的配置区（约第 13-17 行）：
   ```javascript
   const LeaderboardAPI = {
     // ========== 配置区 ==========
     // 是否显示"今日榜"功能（设为 false 暂时隐藏，设为 true 重新显示）
     showDailyRanking: false,
     // ===========================
   ```

3. 将 `showDailyRanking: false,` 改为 `showDailyRanking: true,`

4. 保存文件即可

## 📍 影响范围

此配置会影响以下页面：
- `formallm1/en/leaderboard-lean.html` - Lean 赛道排行榜（英文）
- `formallm1/en/leaderboard-litex.html` - Litex 赛道排行榜（英文）
- `formallm1/cn/leaderboard-lean.html` - Lean 赛道排行榜（中文）
- `formallm1/cn/leaderboard-litex.html` - Litex 赛道排行榜（中文）

## 🎯 效果对比

### 启用时 (showDailyRanking: true)
页面会显示两个切换按钮：
- 今日榜 / 总榜
- Daily / Overall

用户可以在两者之间切换查看。

### 禁用时 (showDailyRanking: false) - 当前状态
页面只显示总榜数据，不显示切换按钮。
界面更简洁，只展示累计排名。

## ⚠️ 注意事项

- 修改后无需清除缓存，刷新页面即可生效
- 所有代码都保留完整，只是暂时不执行
- 随时可以通过修改配置重新启用

---
*创建日期：2025-11-04*
*最后更新：2025-11-04*

