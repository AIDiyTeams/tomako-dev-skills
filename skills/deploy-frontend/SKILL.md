---
name: deploy-frontend
description: Deploy Tomako frontend from local tomako-workspace to production without git push. Use when the user invokes $deploy-frontend, asks for local frontend deploy, hotfix deploy, or wants to ship uncommitted Tomako changes to 168 faster than GitHub Actions.
---

# Tomako 前端本地直部署 Skill

本 Skill 位于 `tomako-dev-skills/skills/deploy-frontend/`，在 **tomako-workspace 根目录** 生效。

触发词：`$deploy-frontend`、本地部署前端、未提交代码部署、热修复前端。

## 何时用这个 Skill

优先使用本地直部署：

- 本地 UI/文案/交互改动，想立刻在 `https://tomako.ai` 验证
- 改动尚未 commit，或不想等 CI + GitHub Actions 队列
- 只需要替换 frontend，不影响 backend / MySQL / Redis / Nginx

仍应走 GitHub Workflow 的场景：

- 合并到 `main` 后的正式发布
- 需要团队可见的 CI 审计记录
- 多人协作、需要以 git SHA 为准的回滚与追溯

## 执行协议

1. 确认 `CIBOS_SSH_KEY` 已设置（或本机有可用的 fallback 密钥）
2. 读 [references/server-config.md](references/server-config.md) 和 [references/troubleshooting.md](references/troubleshooting.md)
3. 在 workspace 根目录执行脚本（默认含 preflight）

## 默认配置

| 项 | 默认值 |
| --- | --- |
| SSH 密钥 | `CIBOS_SSH_KEY`（未设置则探测 `github_deploy_key` / `id_ed25519`） |
| 服务器 | `root@47.239.95.168:22` |
| 本地代码 | `<workspace>/Tomako` |
| 远程目录 | `/opt/cibos/foldos` |

## 常用命令

```bash
# workspace 根目录
export CIBOS_SSH_KEY=~/.ssh/github_deploy_key

# 完整流程
./tomako-dev-skills/scripts/deploy-frontend-local.sh full

# 跳过 preflight
SKIP_PREFLIGHT=1 ./tomako-dev-skills/scripts/deploy-frontend-local.sh full

# 只 rebuild（代码已在服务器）
./tomako-dev-skills/scripts/deploy-frontend-local.sh deploy

# 清空远程再同步（本地删过文件时）
CLEAN_REMOTE=1 ./tomako-dev-skills/scripts/deploy-frontend-local.sh sync
```

## Agent 执行模板

用户说 `$deploy-frontend` 时：

```bash
./tomako-dev-skills/scripts/deploy-frontend-local.sh full
```

用户说「不用检查直接上」：

```bash
SKIP_PREFLIGHT=1 ./tomako-dev-skills/scripts/deploy-frontend-local.sh full
```

## 交付前答复要求

- 部署模式（Podman / Docker Compose）
- 是否执行 preflight
- 健康检查结果
- 是否有未提交本地改动

## 相关文档

- 脚本：`tomako-dev-skills/scripts/deploy-frontend-local.sh`
- 服务器：`Tomako-portal/deploy/SERVERS.md`
- 正式 CI/CD：`Tomako/.github/DEPLOYMENT.md`
