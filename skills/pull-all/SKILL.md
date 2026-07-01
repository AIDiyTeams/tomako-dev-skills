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
├── Tomako-FE/
├── Tomako-portal/
├── Skills-OL/
├── tomako-dev-skills/
└── Tomako2/          # 个人仓库：--repo Tomako2 单独拉取
```

## 单仓库选择

只拉个别仓库时用 `--repo`（别名同 [push-all](../push-all/SKILL.md)：`frontend`、`portal`、`dev-skills` 等）：

```bash
./tomako-dev-skills/scripts/pull-all.sh pull --repo Tomako-FE
./tomako-dev-skills/scripts/pull-all.sh pull --repo portal
```

## 覆盖仓库

以 **tomako-workspace 根目录**为基准，默认处理以下 git 仓库（不存在则跳过）：

| 目录 | 说明 |
| --- | --- |
| `Tomako-FE/` | 前端 |
| `Tomako-portal/` 或 `cibos-portal/` | 后端（二选一） |
| `Skills-OL/` | 在线 Skills |
| `tomako-dev-skills/` | 本 skills 仓库 |

目录名不同时用 `LOCAL_FRONTEND_DIR` 等覆盖。若需把`cc-connect` 等纳入**默认全量**拉取，设置 `EXTRA_GIT_REPOS="cc-connect"`。

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

## 冲突说明与继续执行要求

遇到冲突时，Agent 不能只把脚本输出原样甩给用户，也不能只说“有冲突，跳过”。必须用非技术语言说明：

1. 双方分别改了什么：例如远端新增了哪些官网工具、你本地新增了哪些工具、同一份上线记录里两边各写了什么。
2. 会影响哪里：例如官网工具入口、页面文案、在线生成入口、上线记录、Skill 规则文档、部署说明。
3. 建议怎么处理：例如两边都保留、以远端为主、以本地为主，或某一段需要用户判断。

如果用户已经给出处理选择，Agent 应继续完成当前拉取流程：解决冲突、确认没有未解决冲突、再继续后续 pull / push / 部署步骤。不要在用户已经确认方案后停在“请再次执行”这一步。

只有以下情况才可以停止等待用户：

- 用户没有给出取舍，且不同选择会丢失产品能力、文案、上线记录或 Skill 规则。
- 继续处理会覆盖用户明确要求保留的本地内容。
- 需要外部权限、密钥、发布窗口或服务器状态，当前环境无法完成。

## 交付前答复要求

汇总每个仓库的结果：已更新 / 无需更新 / 已自动 install / 失败，若有冲突列出完整文件路径。只有仓库不存在、无法识别分支等非业务处理场景才使用“跳过”。

若发生过冲突，交付时还要说明最终采用的处理方式，例如“两边工具都保留”“Skill 规则冲突段以远端为主，同时保留本地新增规则”。

## 相关

- 推送改动：`skills/push-all/SKILL.md`（`$push-all` / `$提交`）
- 路径解析：`scripts/lib/workspace-paths.sh`
