# tomako-dev-skills Agent 入口

本目录是 **Tomako 团队工程协作 Skills** 的 canonical 来源。

**工作区根目录**（文件夹名称自定）：需同时包含 `Tomako/`、`Tomako-portal/`、`tomako-dev-skills/`。在此根目录打开 Cursor / Claude Code / Codex 时，先运行 `./tomako-dev-skills/install.sh` 将 skills 链接到各平台目录（`.cursor/skills/`、`.claude/skills/`、`.codex/skills/` 等）。

## 可用触发词

| 触发词 | Skill | 用途 |
| --- | --- | --- |
| `$programmatic-seo` / `$pseo` | programmatic-seo | Tool/SEO 页面开发、验收、复盘 |
| `$deploy-frontend` | deploy-frontend | 本地未提交代码直部署 frontend |

## 前置条件

```bash
export CIBOS_SSH_KEY=~/.ssh/your_deploy_key   # 团队统一 SSH 密钥
./tomako-dev-skills/install.sh               # 首次或 skill 更新后
```

## Agent 规则

1. 收到 `$deploy-frontend` → 读取 `skills/deploy-frontend/SKILL.md` 并执行 `scripts/deploy-frontend-local.sh full`
2. 收到 `$programmatic-seo` / `$pseo` → 读取 `skills/programmatic-seo/SKILL.md` 并按 Gate 协议执行
3. 所有路径以**工作区根目录**（含 `Tomako/`、`Tomako-portal/`、`tomako-dev-skills/`，名称自定）为基准，不要假设 skill 在 `Tomako/` 子目录内
4. 营销/GTM skills 仍在 `Tomako/.agents/skills/`，不在本目录

## Workspace 子项目

- `Tomako/` — Next.js 前端
- `Tomako-portal/` — Java 后端
- `Skills-OL/` — cc-connect 在线 Skills 与脚本
