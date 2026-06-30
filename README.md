# tomako-dev-skills

Tomako 团队工程协作 Skills 与部署脚本。独立仓库：`AIDiyTeams/tomako-dev-skills`，以 `git clone` 或 submodule 挂载到你平时打开 AI 助手的目录下；安装脚本不强制同级项目名称。

## 包含的 Skills（Phase 1）

| Skill | 触发词 | 说明 |
| --- | --- | --- |
| programmatic-seo | `$programmatic-seo` / `$pseo` | Tool/SEO 页全链路开发与验收 |
| deploy-frontend | `$deploy-frontend` | 本地直部署 frontend → 168 生产 |

Phase 2 计划：`deploy-backend`、`deploy-skills-ol`、`dev-skills-ol`

## 快速开始

```bash
# 1. 安装 skill 链接（默认链接到 tomako-dev-skills 的父目录）
./tomako-dev-skills/install.sh

# 2. 配置团队 SSH 密钥（shell profile 或当前终端）
export CIBOS_SSH_KEY=~/.ssh/github_deploy_key

# 3. 部署前端（同步 + preflight + 远程 build）
./tomako-dev-skills/scripts/deploy-frontend-local.sh full
```

## 目录结构

```text
tomako-dev-skills/
├── skills/                  # Agent Skills（install.sh 链接到各平台 skills 目录）
├── scripts/                 # 可执行部署/联调脚本
│   └── lib/                 # workspace 路径、SSH 公共逻辑
├── config/                  # 默认环境变量（不含密钥）
├── install.sh               # symlink 安装器
└── AGENTS.md                # Agent 入口说明
```

## 与 Tomako 营销 Skills 的关系

- **本仓库**：工程开发、部署、联调（跨 Tomako / Tomako-portal / Skills-OL）
- **`Tomako/.agents/skills/`**：40+ 营销/GTM skills，暂保留在前端仓库

## 安装与更新

`tomako-dev-skills` 是团队给 AI 助手准备的工程协作 Skills。安装后，在**工作区根目录**即可让 Cursor / Claude Code / Codex 使用 `$programmatic-seo`、`$deploy-frontend` 等触发词。

### 准备条件

工作区根目录名称自定，通常是你平时打开 AI 助手的那个 multi-repo 目录。安装本身不要求同时存在前端、后端和 Skills-OL；相关脚本需要项目代码时，可用环境变量指定路径。

```text
你的工作目录/          # 名称随意
  Tomako/             # 前端，默认路径；不同名称可设 LOCAL_FRONTEND_DIR
  Tomako-portal/      # 后端，或 cibos-portal/；需要时可设 LOCAL_BACKEND_DIR
  Skills-OL/           # 常见，非必需
  tomako-dev-skills/   # clone 后出现
```

### 首次安装

```bash
cd /你的工作目录/路径
git clone git@github.com:AIDiyTeams/tomako-dev-skills.git
./tomako-dev-skills/install.sh
```

安装成功后会看到类似输出：

```text
linked .cursor/skills/programmatic-seo
linked .claude/skills/deploy-frontend
完成
```

重新打开 AI 助手后，可直接输入例如：

```text
$programmatic-seo 帮我规划一个新的 SEO 工具页
$programmatic-seo 帮我检查这个工具页是否符合上线标准，不要改代码，先输出问题清单
```

### 更新 skills

团队更新 skills 后，在工作区根目录执行：

```bash
cd tomako-dev-skills && git pull && cd ..
./tomako-dev-skills/install.sh
```

然后重新打开 AI 助手即可。

### Submodule 方式（可选）

若工作区用 git submodule 管理，在工作区根目录执行：

```bash
git submodule add git@github.com:AIDiyTeams/tomako-dev-skills.git tomako-dev-skills
./tomako-dev-skills/install.sh
```

### 关于 CIBOS_SSH_KEY

仅在使用 `$deploy-frontend` 部署前端时需要：

```bash
export CIBOS_SSH_KEY=~/.ssh/your_key
```

部署脚本需用 SSH 私钥登录服务器；`$programmatic-seo` 等产品/运营向能力无需设置。

## 相关文档

- 服务器清单：`Tomako-portal/deploy/SERVERS.md`
- GitHub 正式 CI/CD：`Tomako/.github/DEPLOYMENT.md`
