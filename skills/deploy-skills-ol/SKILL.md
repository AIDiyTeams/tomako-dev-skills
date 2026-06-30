---
name: deploy-skills-ol
description: Deploy Skills-OL to cc-connect server (git pull, npm install, restart). Use when the user invokes $deploy-skills-ol, $部署skills, or needs Agent runtime updated after Skills-OL changes during programmatic SEO work.
---

# Skills-OL 部署 Skill

将 **Skills-OL** 同步到 **124 cc-connect** 服务器，使 Codex Agent 运行最新 skill / 脚本。默认以 `tomako-workspace` 根目录执行。

触发词：`$deploy-skills-ol`、`$部署skills`、部署 Skills-OL、更新 cc-connect skills。

## 何时使用

程序化 SEO / Agent-backed 工具开发中，改了 `Skills-OL/` 并已 **push 到 GitHub** 后：

- Git push **≠** 124 上 Agent 已更新
- 需要本 skill 在服务器执行 `git pull` +（按需）`npm install` + `restart cc-connect`

与 `$deploy-frontend` 对称：前者管 168 前端，本 skill 管 124 Agent 运行时。

## 执行协议

1. 确认 `TOMAKO_SSH_KEY` 已设置
2. 读 [references/server-config.md](references/server-config.md)
3. **先 push Skills-OL**（`$提交 --repo Skills-OL` 或单独 push）
4. 在 workspace 根目录执行脚本

## 默认配置

| 项 | 默认值 |
| --- | --- |
| SSH 密钥 | `TOMAKO_SSH_KEY` |
| 服务器 | `root@8.210.246.124:22` |
| 远端目录 | `/home/ubuntu/Skills-OL` |
| git 操作用户 | `ubuntu` |
| 分支 | `main` |
| 服务 | `cc-connect` |

## 常用命令

```bash
export TOMAKO_SSH_KEY=~/.ssh/github_deploy_key

# 完整部署（推荐）
./tomako-dev-skills/scripts/deploy-skills-ol.sh full

# 仅查看本地/远端 commit 与服务状态
./tomako-dev-skills/scripts/deploy-skills-ol.sh status

# 只 pull + npm，不重启
./tomako-dev-skills/scripts/deploy-skills-ol.sh pull

# 只重启 cc-connect
./tomako-dev-skills/scripts/deploy-skills-ol.sh restart

# 查看上次部署结果（或 full 结束时的结构化摘要）
./tomako-dev-skills/scripts/deploy-skills-ol.sh report
./tomako-dev-skills/scripts/deploy-skills-ol.sh full --json   # JSON 输出
```

部署结果写入 `tomako-dev-skills/.cache/deploy-skills-ol-last.json`，包含本地/远端 commit、npm、cc-connect 状态。

## Agent 执行模板

用户说 `$deploy-skills-ol` 或程序化 SEO 开发完成 Skills-OL 改动时：

```bash
./tomako-dev-skills/scripts/deploy-skills-ol.sh status
./tomako-dev-skills/scripts/deploy-skills-ol.sh full
```

若 `preflight` 报未 push：先 `$提交 --repo Skills-OL`，再执行 `full`。

## 交付前答复要求

- 本地与远端 commit（short SHA）
- 是否执行 npm install、是否重启 cc-connect
- `systemctl` / health 检查结果
- 若未 push 就部署，必须明确警告远端未包含本地改动
- 引用 `report` 或 `.cache/deploy-skills-ol-last.json` 中的结构化结果

## 相关

- 程序化 SEO 运行时门槛：`skills/programmatic-seo/references/p0-runtime-gates.md`
- Skills-OL 上线指南：`Skills-OL/docs/llm-task-deployment-guide.md`
- 服务器详情：`Tomako-portal/deploy/SERVERS.md`（124 cc-connect 章节）
