# tomako-dev-skills

Tomako 团队工程协作 Skills 与部署脚本。独立仓库：`AIDiyTeams/tomako-dev-skills`，以 `git clone` 或 submodule 挂载到你平时打开 AI 助手的目录下；安装脚本不强制同级项目名称。

## 包含的 Skills（Phase 1）

| Skill | 触发词 | 说明 |
| --- | --- | --- |
| programmatic-seo | `$programmatic-seo` / `$pseo` | Tool/SEO 页全链路开发与验收 |
| deploy-frontend | `$deploy-frontend` | 本地直部署 frontend → 168 生产 |
| pull-all | `$pull-all` | 拉取 workspace 内全部 Tomako 相关仓库最新代码 |
| push-all | `$push-all` / `$提交` | 提交并推送各仓库本地改动 |
| deploy-skills-ol | `$deploy-skills-ol` / `$部署skills` | Skills-OL → 124 cc-connect |
| i18n-translate | `$i18n-translate` / `$翻译` | 批量生成 Tomako-style i18n messages 多语言文案 |

Phase 2 计划：`deploy-backend`、`dev-skills-ol`

## 快速开始

```bash
# 1. 安装 skill 链接（默认链接到 tomako-dev-skills 的父目录）
./tomako-dev-skills/install.sh

# 2. 配置团队 SSH 密钥（shell profile 或当前终端）
export TOMAKO_SSH_KEY=~/.ssh/github_deploy_key

# 3. 日常同步代码
./tomako-dev-skills/scripts/pull-all.sh pull

# 4. 部署前端（同步 + preflight + 远程 build）
./tomako-dev-skills/scripts/deploy-frontend-local.sh full

# 5. 部署 Skills-OL 到 cc-connect（需先 push Skills-OL）
./tomako-dev-skills/scripts/deploy-skills-ol.sh full

# 6. 批量生成多语言 messages（需 OPENAI_API_KEY；也可用 $i18n-translate）
OPENAI_API_KEY=... ./tomako-dev-skills/skills/i18n-translate/scripts/translate-messages.sh \
  --project ./Tomako \
  --provider=openai \
  --locale es
```

## 目录结构

```text
tomako-dev-skills/
├── skills/                  # Agent Skills（install.sh 链接到各平台 skills 目录）
├── scripts/                 # 可执行部署/联调脚本
│   └── lib/                 # workspace 路径、SSH 公共逻辑
├── config/                  # 默认环境变量（不含密钥）
├── install.sh               # symlink 安装器
├── AGENTS.md                # Agent 入口说明
└── .github/
    ├── ISSUE_TEMPLATE/      # Issue 表单（参考 VoiceHub）
    └── workflows/           # 飞书通知等 CI
```

## 与 Tomako 营销 Skills 的关系

- **本仓库**：工程开发、部署、联调（跨 Tomako / Tomako-portal / Skills-OL）
- **`Tomako/.agents/skills/`**：40+ 营销/GTM skills，暂保留在前端仓库

## 安装与更新

`tomako-dev-skills` 是团队给 AI 助手准备的工程协作 Skills。安装后，在**工作区根目录**即可让 Cursor / Claude Code / Codex 使用 `$programmatic-seo`、`$deploy-frontend` 等触发词。

### 准备条件

工作区根目录名称自定，团队标准为 **`tomako-workspace`**。安装本身不要求同时存在前端、后端和 Skills-OL；相关脚本需要项目代码时，可用环境变量指定路径。

```text
tomako-workspace/        # 在此打开 Cursor，脚本从此根目录执行
  Tomako/                # 前端，默认路径；不同名称可设 LOCAL_FRONTEND_DIR
  Tomako-portal/         # 后端，或 cibos-portal/
  Skills-OL/
  tomako-dev-skills/     # clone 后出现
  Tomako2/               # 可选；--repo Tomako2 或 EXTRA_GIT_REPOS
```

### 首次安装

```bash
cd /你的工作目录/路径
git clone git@github.com:AIDiyTeams/tomako-dev-skills.git
./tomako-dev-skills/install.sh
```

安装成功后会显示可用触发词列表；失败时汇总错误/警告。详细日志可加 `INSTALL_VERBOSE=1`：

```bash
INSTALL_VERBOSE=1 ./tomako-dev-skills/install.sh
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

### 关于 TOMAKO_SSH_KEY

仅在使用 `$deploy-frontend` 部署前端时需要：

```bash
export TOMAKO_SSH_KEY=~/.ssh/your_key
```

部署脚本需用 SSH 私钥登录服务器；`$programmatic-seo` 等产品/运营向能力无需设置。

## 飞书推送通知（GitHub Actions）

`main` 分支 **push** 与下表事件会触发飞书通知，逻辑对齐 [action-feishu](https://github.com/Lirzh/action-feishu)。Workflow：`.github/workflows/notify-feishu.yml`。

| 事件 | 触发时机 |
| --- | --- |
| `push` | 推送到 `main` |
| `pull_request` | PR 新建 / 关闭 / 重开（含是否已合并） |
| `pull_request_review` | 提交 PR 评审（通过 / 需修改 / 评论） |
| `issues` | Issue 新建 / 关闭 / 重开 |
| `release` | Release 发布 / 删除 |
| `discussion` | Discussion 新建 / 关闭 / 重开（需仓库开启 Discussions） |

Issue 表单参考 [VoiceHub ISSUE_TEMPLATE](https://github.com/laoshuikaixue/VoiceHub/tree/main/.github/ISSUE_TEMPLATE)；**功能建议**中的「功能类别 / 功能概述 / 优先级」会在飞书里结构化展示。

### 一次性配置

1. **飞书群机器人**：群设置 → 群机器人 → 自定义机器人 → 复制 Webhook URL
   - 若启用了「签名校验」，复制签名密钥
   - 若启用了「自定义关键词」，记下关键词（如 `GitHub`）
2. **GitHub Secrets**（仓库 Settings → Secrets and variables → Actions）：

| Secret | 必填 | 说明 |
| --- | --- | --- |
| `FEISHU_WEBHOOK_URL` | 是 | 飞书机器人 Webhook |
| `FEISHU_WEBHOOK_SECRET` | 否 | 飞书机器人签名密钥；机器人开启「签名校验」时必填 |
| `FEISHU_MESSAGE_TITLE` | 否 | 消息首行；可自定义标题。只有机器人开启关键词验证时，标题才必须包含关键词 |

3. 合并 workflow 后 push 到 `main` 即可生效；未配置 `FEISHU_WEBHOOK_URL` 时 workflow 会跳过发送（不报错）。飞书接口返回业务错误时，workflow 会失败并打印响应 body。

## 相关文档

- 服务器清单：`Tomako-portal/deploy/SERVERS.md`
- GitHub 正式 CI/CD：`Tomako/.github/DEPLOYMENT.md`
