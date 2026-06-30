# tomako-dev-skills

Tomako 团队工程协作 Skills 与部署脚本（试点版，位于 monorepo 内）。

未来计划：拆为 private 仓库 `AIDiyTeams/tomako-dev-skills`，以 git submodule 挂载到 `tomako-workspace`。

## 包含的 Skills（Phase 1）

| Skill | 触发词 | 说明 |
| --- | --- | --- |
| programmatic-seo | `$programmatic-seo` / `$pseo` | Tool/SEO 页全链路开发与验收 |
| deploy-frontend | `$deploy-frontend` | 本地直部署 frontend → 168 生产 |

Phase 2 计划：`deploy-backend`、`deploy-skills-ol`、`dev-skills-ol`

## 快速开始

```bash
# 1. 在 tomako-workspace 根目录安装 skill 链接
./tomako-dev-skills/install.sh

# 2. 配置团队 SSH 密钥（shell profile 或当前终端）
export CIBOS_SSH_KEY=~/.ssh/github_deploy_key

# 3. 部署前端（同步 + preflight + 远程 build）
./tomako-dev-skills/scripts/deploy-frontend-local.sh full
```

## 目录结构

```text
tomako-dev-skills/
├── skills/                  # Agent Skills（挂载到 .cursor/skills/）
├── scripts/                 # 可执行部署/联调脚本
│   └── lib/                 # workspace 路径、SSH 公共逻辑
├── config/                  # 默认环境变量（不含密钥）
├── install.sh               # symlink 安装器
└── AGENTS.md                # Agent 入口说明
```

## 与 Tomako 营销 Skills 的关系

- **本仓库**：工程开发、部署、联调（跨 Tomako / Tomako-portal / Skills-OL）
- **`Tomako/.agents/skills/`**：40+ 营销/GTM skills，暂保留在前端仓库

## Submodule 迁移（未来）

```bash
# 当独立仓库就绪后：
git submodule add git@github.com:AIDiyTeams/tomako-dev-skills.git tomako-dev-skills
./tomako-dev-skills/install.sh
```

## 相关文档

- 服务器清单：`Tomako-portal/deploy/SERVERS.md`
- GitHub 正式 CI/CD：`Tomako/.github/DEPLOYMENT.md`
