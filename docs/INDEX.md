# 📚 文档中心

欢迎来到 ForMaLLM 竞赛网站文档中心！这里包含了所有您需要的文档。

## 🎯 我想...

### 部署网站

- 🚀 [**5分钟快速部署**](../QUICKSTART_SERVER.md) - 最快上手指南
- 📘 [**完整部署指南**](../DEPLOYMENT.md) - 详细部署步骤
- 🔧 [**服务器脚本说明**](../server/README.md) - 自动化脚本详解

### 管理网站

- 📖 [**使用指南**](USAGE_GUIDE.md) - 管理员和开发者指南
- 🔄 [**GitHub Actions 说明**](../.github/workflows/README.md) - 自动化工作流

### 了解项目

- 📄 [**项目主页**](../README.md) - 项目概览和特性
- 🏗️ [**架构说明**](#架构概览) - 系统架构图

## 📖 文档列表

### 快速开始

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [QUICKSTART_SERVER.md](../QUICKSTART_SERVER.md) | 5 分钟快速部署到云服务器 | 初次部署者 |
| [README.md](../README.md) | 项目概览和快速开始 | 所有人 |

### 部署指南

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [DEPLOYMENT.md](../DEPLOYMENT.md) | GitHub Pages 和云服务器完整部署流程 | 管理员 |
| [server/README.md](../server/README.md) | 服务器脚本详细说明 | 开发者、管理员 |
| [.github/workflows/README.md](../.github/workflows/README.md) | GitHub Actions 工作流配置 | DevOps |

### 使用和维护

| 文档 | 描述 | 适合人群 |
|------|------|----------|
| [USAGE_GUIDE.md](USAGE_GUIDE.md) | 日常使用和维护指南 | 管理员、开发者 |

## 🏗️ 架构概览

```
┌──────────────────────────────────────────────────────────────┐
│                         用户浏览器                             │
│              (访问 https://your-site.github.io)              │
└─────────────────────────┬────────────────────────────────────┘
                          │ HTTPS
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                   GitHub Pages (CDN)                          │
│  ┌────────────────────────────────────────────────────┐      │
│  │  静态网站内容                                        │      │
│  │  • HTML/CSS/JavaScript                             │      │
│  │  • assets/data/leaderboard.json (排行榜数据)        │      │
│  └────────────────────────────────────────────────────┘      │
└─────────────────────────▲────────────────────────────────────┘
                          │ Git Push
                          │ (自动部署)
                          │
┌─────────────────────────┴────────────────────────────────────┐
│                     GitHub Repository                         │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Git 仓库                                           │      │
│  │  • 网站源代码                                        │      │
│  │  • 自动化脚本                                        │      │
│  │  • GitHub Actions 工作流                            │      │
│  └────────────────────────────────────────────────────┘      │
└─────────────▲────────────────────────────────────────────────┘
              │ Git Commit & Push
              │ (更新排行榜数据)
              │
    ┌─────────┴──────────┐
    │                    │
┌───┴─────────────────┐  │  ┌─────────────────────────┐
│  云服务器 Cron       │  │  │  GitHub Actions         │
│  ┌─────────────────┐│  │  │  ┌─────────────────┐   │
│  │ 定时任务         ││  └──┤  │ 工作流          │   │
│  │ auto_update.sh  ││     │  │ (可选)          │   │
│  └────────┬────────┘│     │  └────────┬────────┘   │
│           │          │     │           │            │
│  ┌────────┴────────┐│     │  ┌────────┴────────┐   │
│  │ Python 脚本      ││     │  │ Python 脚本     │   │
│  │ fetch_leaderboard││     │  │ fetch_leaderboard  │
│  └────────┬────────┘│     │  └────────┬────────┘   │
└───────────┼─────────┘     └───────────┼────────────┘
            │                            │
            │  HTTP Request              │
            │  (获取排行榜数据)            │
            └────────────┬───────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────┐
│           ForMaLLM 竞赛 API (http://121.43.230.124)           │
│  ┌────────────────────────────────────────────────────┐      │
│  │  REST API                                           │      │
│  │  • GET /ranking_list/daily  (每日排行榜)            │      │
│  │  • GET /ranking_list/overall (总排行榜)             │      │
│  │  • 需要 X-API-Key 认证                              │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

## 🔄 数据流程

### 1. 自动更新流程（推荐）

```
定时触发 (Cron/GitHub Actions)
    ↓
执行 fetch_leaderboard.py
    ↓
调用 ForMaLLM API
    ↓
解析并转换数据格式
    ↓
生成 leaderboard.json
    ↓
Git Commit & Push
    ↓
GitHub Pages 自动部署
    ↓
用户看到最新数据
```

### 2. 手动更新流程

```
管理员执行脚本
    ↓
python3 server/fetch_leaderboard.py
    ↓
检查生成的 JSON 文件
    ↓
git add & commit & push
    ↓
GitHub Pages 更新
```

## 🎓 学习路径

### 初学者路径

1. ✅ 阅读 [README.md](../README.md) 了解项目
2. ✅ 按照 [QUICKSTART_SERVER.md](../QUICKSTART_SERVER.md) 快速部署
3. ✅ 查看 [USAGE_GUIDE.md](USAGE_GUIDE.md) 学习基本操作
4. ✅ 根据需要查阅其他详细文档

### 管理员路径

1. ✅ 完成基础部署
2. ✅ 阅读 [DEPLOYMENT.md](../DEPLOYMENT.md) 了解完整架构
3. ✅ 学习 [USAGE_GUIDE.md](USAGE_GUIDE.md) 的管理部分
4. ✅ 配置监控和告警
5. ✅ 制定备份策略

### 开发者路径

1. ✅ 了解项目结构（见 [README.md](../README.md)）
2. ✅ 阅读 [server/README.md](../server/README.md) 了解脚本原理
3. ✅ 查看 [USAGE_GUIDE.md](USAGE_GUIDE.md) 的开发者部分
4. ✅ 本地搭建开发环境
5. ✅ 进行自定义开发

## 🔍 快速查找

### 常见任务

- **首次部署** → [QUICKSTART_SERVER.md](../QUICKSTART_SERVER.md)
- **修改网站内容** → [USAGE_GUIDE.md - 管理员指南](USAGE_GUIDE.md#管理员指南)
- **调整更新频率** → [USAGE_GUIDE.md - 管理排行榜数据](USAGE_GUIDE.md#管理排行榜数据)
- **故障排查** → [DEPLOYMENT.md - 故障排查](../DEPLOYMENT.md#故障排查)
- **添加新功能** → [USAGE_GUIDE.md - 开发者指南](USAGE_GUIDE.md#开发者指南)

### 技术细节

- **API 文档** → [server/README.md](../server/README.md)
- **脚本说明** → [server/README.md](../server/README.md)
- **GitHub Actions** → [.github/workflows/README.md](../.github/workflows/README.md)
- **数据格式** → [DEPLOYMENT.md - 数据格式](../DEPLOYMENT.md#数据格式)

## 📞 获取帮助

### 文档没有解决您的问题？

1. 🔍 使用 GitHub 搜索查找类似问题
2. 📖 查看 [FAQ](USAGE_GUIDE.md#常见问题)
3. 🐛 提交 [Issue](https://github.com/your-username/alailab/issues)
4. 📧 联系项目维护者

### 提交 Issue 的最佳实践

好的 Issue 应该包含：
- ✅ 清晰的标题
- ✅ 详细的问题描述
- ✅ 复现步骤
- ✅ 错误日志或截图
- ✅ 环境信息（操作系统、浏览器等）

## 🤝 贡献文档

发现文档有误或需要改进？

1. Fork 本仓库
2. 编辑文档
3. 提交 Pull Request

我们欢迎任何形式的贡献！

## 📋 文档版本

- **最后更新**: 2025-10-30
- **文档版本**: 1.0.0
- **适用项目版本**: 1.0.0+

## 🔖 相关链接

- 🌐 [项目主页](https://github.com/your-username/alailab)
- 🎯 [在线演示](https://your-username.github.io/alailab/)
- 📊 [排行榜](https://your-username.github.io/alailab/cn/leaderboard.html)
- 🐛 [问题追踪](https://github.com/your-username/alailab/issues)
- 💬 [讨论区](https://github.com/your-username/alailab/discussions)

---

**提示**: 建议从 [快速开始](#快速开始) 部分开始！

