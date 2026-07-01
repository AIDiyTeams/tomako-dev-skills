---
name: pull-all
description: Pull latest remote code for Tomako workspace git repos (all or selected via --repo). Use when the user invokes $pull-all, $拉取, asks to sync all or specific local repos.
---

# Tomako 全仓库拉取 Skill

触发词：`$pull-all` / `$拉取` / `$拉取代码`、拉取全部或**指定**仓库。

## 工作区约定（tomako-workspace）

在 **`tomako-workspace` 根目录**打开 Cursor，所有命令从此处执行（不要 `cd` 进 `tomako-dev-skills` 再跑）：

```bash
cd /path/to/tomako-workspace
./tomako-dev-skills/scripts/pull-all.sh pull
```

```text
tomako-workspace/
├── Tomako/
├── Tomako-portal/
├── Skills-OL/
├── tomako-dev-skills/
└── Tomako2/          # 个人仓库：--repo Tomako2 单独拉取
```

## 单仓库选择

只拉个别仓库时用 `--repo`（别名同 [push-all](../push-all/SKILL.md)：`frontend`、`portal`、`dev-skills` 等）：

```bash
./tomako-dev-skills/scripts/pull-all.sh pull --repo Tomako
./tomako-dev-skills/scripts/pull-all.sh pull --repo portal
```

## 覆盖仓库

以 **tomako-workspace 根目录**为基准，默认处理以下 git 仓库（不存在则跳过）：

| 目录 | 说明 |
| --- | --- |
| `Tomako/` | 前端 |
| `Tomako-portal/` 或 `cibos-portal/` | 后端（二选一） |
| `Skills-OL/` | 在线 Skills |
| `tomako-dev-skills/` | 本 skills 仓库 |

目录名不同时用 `LOCAL_FRONTEND_DIR` 等覆盖。若需把 `Tomako2`、`cc-connect` 等纳入**默认全量**拉取，设置 `EXTRA_GIT_REPOS="Tomako2 cc-connect"`。

## 执行协议

1. **cwd = tomako-workspace 根目录**
2. 默认先 `status` 了解各仓库状态（可选）
3. 执行 `pull` 拉取远程最新；有未提交改动时默认自动 stash → pull/rebase → stash pop，不把仓库标记为跳过
4. 若本次处理的仓库包含 `tomako-dev-skills/`，且该仓库拉取成功且无冲突，脚本会自动执行 `./tomako-dev-skills/install.sh`，让新/更新后的 skills 立即挂载到 Agent 入口

## 常用命令

```bash
# 查看各仓库分支、领先/落后、未提交改动
./tomako-dev-skills/scripts/pull-all.sh status

# 拉取全部（默认 rebase；有未提交改动时默认 autostash）
./tomako-dev-skills/scripts/pull-all.sh pull

# 禁止自动 stash：遇到未提交改动时失败并列出文件
AUTOSTASH=0 ./tomako-dev-skills/scripts/pull-all.sh pull

# 只拉取 skills 仓库；成功后默认自动 install
./tomako-dev-skills/scripts/pull-all.sh pull --repo tomako-dev-skills

# 特殊场景禁止拉取后自动 install
AUTO_INSTALL_DEV_SKILLS=0 ./tomako-dev-skills/scripts/pull-all.sh pull --repo tomako-dev-skills
```

## Agent 执行模板

用户说 `$pull-all` 时：

```bash
./tomako-dev-skills/scripts/pull-all.sh status
./tomako-dev-skills/scripts/pull-all.sh pull
```

默认流程已经会保护本地未提交改动并继续拉取；不要因为工作区 dirty 就跳过仓库。

用户说「拉取 skills」「拉取 tomako-dev-skills」时：

```bash
./tomako-dev-skills/scripts/pull-all.sh status --repo tomako-dev-skills
./tomako-dev-skills/scripts/pull-all.sh pull --repo tomako-dev-skills
```

第二步成功后会自动执行 `./tomako-dev-skills/install.sh`；Agent 不需要再单独补跑 install。

## 冲突与异常

- **有未提交改动**：默认自动 stash，拉取后恢复；只有显式 `AUTOSTASH=0` 时才失败并列出文件
- **pull/rebase 产生冲突**：脚本列出冲突文件完整路径，**不自动解决**；告知用户人工处理后重新执行 `$pull-all` 或 `$push-all`
- **stash pop 产生冲突**：脚本列出冲突文件完整路径；告知用户先人工解决这些冲突，再执行 `$push-all` 提交
- **tomako-dev-skills install 失败**：脚本标记失败并保留 `install.sh` 输出；通常是本地已有差异副本，需要用户迁移或删除后重试
- **某仓库不存在**：自动跳过，不报错

## 交付前答复要求

汇总每个仓库的结果：已更新 / 无需更新 / 已自动 install / 失败，若有冲突列出完整文件路径。只有仓库不存在、无法识别分支等非业务处理场景才使用“跳过”。

## 相关

- 推送改动：`skills/push-all/SKILL.md`（`$push-all` / `$提交`）
- 路径解析：`scripts/lib/workspace-paths.sh`
