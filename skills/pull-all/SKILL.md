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
3. 执行 `pull` 拉取远程最新

## 常用命令

```bash
# 查看各仓库分支、领先/落后、未提交改动
./tomako-dev-skills/scripts/pull-all.sh status

# 拉取全部（默认 rebase）
./tomako-dev-skills/scripts/pull-all.sh pull

# 有本地未提交改动时自动 stash → pull → pop
AUTOSTASH=1 ./tomako-dev-skills/scripts/pull-all.sh pull
```

## Agent 执行模板

用户说 `$pull-all` 时：

```bash
./tomako-dev-skills/scripts/pull-all.sh status
./tomako-dev-skills/scripts/pull-all.sh pull
```

用户本地有未提交改动且希望一并拉取：

```bash
AUTOSTASH=1 ./tomako-dev-skills/scripts/pull-all.sh pull
```

## 冲突与异常

- **有未提交改动**：默认跳过该仓库并列出文件；用 `AUTOSTASH=1` 可自动 stash
- **pull 产生冲突**：脚本列出冲突文件，**不自动解决**；告知用户人工处理后重新执行 `$pull-all` 或 `$push-all`
- **某仓库不存在**：自动跳过，不报错

## 交付前答复要求

汇总每个仓库的结果：已更新 / 跳过 / 失败，若有冲突列出完整文件路径。

## 相关

- 推送改动：`skills/push-all/SKILL.md`（`$push-all` / `$提交`）
- 路径解析：`scripts/lib/workspace-paths.sh`
