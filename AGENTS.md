# tomako-dev-skills Agent 入口

本目录是 **Tomako 团队工程协作 Skills** 的 canonical 来源。

**安装与执行目录**：团队在 **`tomako-workspace` 根目录**打开 Cursor（推荐）。若只在 `tomako-dev-skills` 子目录打开，`install.sh` 也会把 skills 装到 `tomako-dev-skills/.cursor/skills/`。

**`$` 技能菜单**：Cursor 根据每个 skill 的 `agents/openai.yaml` 里 **`display_name` / `short_description`** 做模糊匹配（所以 `$程序化` 能唤起 `programmatic-seo` 文件夹，尽管目录名是英文）。中文触发词需在对应 skill 下配置 `agents/openai.yaml`，例如 `display_name: "提交推送 Skill"` 才能匹配 `$提交`。

```text
tomako-workspace/          ← 工作区根（在此打开 IDE）
├── Tomako/                ← 前端
├── Tomako-portal/         ← 后端（或 cibos-portal/）
├── Skills-OL/
├── tomako-dev-skills/     ← 本仓库（skills + 脚本）
├── .cursor/skills/        ← install.sh 生成的链接
└── …                      ← 个人额外仓库（如 Tomako2）可用 --repo 单独操作
```

先运行 `./tomako-dev-skills/install.sh` 将 skills 链接到 `.cursor/skills/`、`.claude/skills/` 等。

## 可用触发词

| 触发词 | Skill | 用途 |
| --- | --- | --- |
| `$programmatic-seo` / `$pseo` | programmatic-seo | Tool/SEO 页面开发、验收、复盘 |
| `$deploy-frontend`/ `$部署前端` | deploy-frontend | 本地未提交代码直部署 frontend |
| `$pull-all` / `$拉取` /  `$拉取代码` | pull-all | 拉取 workspace 内全部 Tomako 相关仓库最新代码 |
| `$push-all` / `$提交` / `$提交代码`| push-all | 提交并推送各仓库本地改动（冲突需人工解决后重试） |
| `$deploy-skills-ol` / `$部署skills` | deploy-skills-ol | Skills-OL 部署到 124 cc-connect（pull + restart） |

## 前置条件

```bash
export TOMAKO_SSH_KEY=~/.ssh/your_deploy_key   # 团队统一 SSH 密钥
./tomako-dev-skills/install.sh               # 首次或 skill 更新后
```

## Agent 规则

1. 收到 `$deploy-frontend` → 读取 `skills/deploy-frontend/SKILL.md` 并执行 `scripts/deploy-frontend-local.sh full`
2. 收到 `$programmatic-seo` / `$pseo` → 读取 `skills/programmatic-seo/SKILL.md` 并按 Gate 协议执行
3. 收到 `$pull-all` / `$拉取` → 读取 `skills/pull-all/SKILL.md`；**cwd 为 tomako-workspace 根目录**，执行 `./tomako-dev-skills/scripts/pull-all.sh pull`（可先 status）；指定仓库时加 `--repo`
4. 收到 `$push-all` / `$提交` / `$提交代码` → 读取 `skills/push-all/SKILL.md`；**cwd 为 tomako-workspace 根目录**，先 `status` 与 diff，再 `push -m "..."`；指定仓库时加 `--repo`；有冲突则列出文件，解决后重试
5. 收到 `$deploy-skills-ol` / `$部署skills` → 读取 `skills/deploy-skills-ol/SKILL.md`；确认 Skills-OL 已 push 后执行 `scripts/deploy-skills-ol.sh full`（程序化 SEO 改 Agent skill 后必做）
6. 默认路径以 `tomako-workspace`（本仓库父目录）为基准；子目录名不同时用 `LOCAL_FRONTEND_DIR`、`LOCAL_BACKEND_DIR`、`LOCAL_SKILLS_OL_DIR` 覆盖；额外仓库纳入默认全量同步时设 `EXTRA_GIT_REPOS="Tomako2 cc-connect"`
7. 营销/GTM skills 仍在 `Tomako/.agents/skills/`，不在本目录

## Workspace 子项目

- `Tomako/` — Next.js 前端
- `Tomako-portal/` 或 `cibos-portal/` — Java 后端
- `Skills-OL/` — cc-connect 在线 Skills 与脚本
