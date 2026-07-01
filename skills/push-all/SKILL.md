---
name: push-all
description: Commit and push local changes across Tomako workspace git repos (all or selected via --repo). Reports conflict files for manual resolution. Use when the user invokes $push-all, $提交, asks to commit/push all or specific repos (e.g. only Tomako-FE).
---

# Tomako 全仓库提交推送 Skill

触发词：`$push-all` / `$提交` / `$提交代码`、提交并推送全部或**指定**仓库。

## 工作区约定（tomako-workspace）

在 **`tomako-workspace` 根目录**执行（与 `$pull-all` 相同）：

```bash
cd /path/to/tomako-workspace
./tomako-dev-skills/scripts/push-all.sh status
./tomako-dev-skills/scripts/push-all.sh push -m "feat: ..."
```

`tomako-workspace` 本身可能是 git 仓库（含 `AGENTS.md` 等），**不在**默认 push 范围内；只操作各子项目目录。

## 单仓库 / 多仓库选择

默认处理 workspace 内**全部**仓库。只提交个别仓库时用 `--repo`（可重复）：

| 仓库 | `--repo` 取值 | 别名 |
| --- | --- | --- |
| 前端 | `Tomako-FE` | `tomako`, `frontend` |
| 后端 | `Tomako-portal` / `cibos-portal` | `portal`, `backend` |
| Skills-OL | `Skills-OL` | `skills-ol` |
| 本仓库 | `tomako-dev-skills` | `dev-skills` |
| 其他子目录 | 目录名本身（如 `Tomako2`） | 须为 tomako-workspace 下含 `.git` 的文件夹 |

```bash
# 只提交前端
./tomako-dev-skills/scripts/push-all.sh push --repo Tomako-FE -m "feat: ..."

# 只提交个人 fork / 实验仓库
./tomako-dev-skills/scripts/push-all.sh push --repo Tomako-FE -m "wip: ..."

# 只提交 skills 仓库 + 前端
./tomako-dev-skills/scripts/push-all.sh push --repo dev-skills --repo frontend -m "..."
```

用户说「只提交 Tomako-FE」「提交前端」「$提交 tomako-dev-skills」时，Agent 应加上对应的 `--repo`。

## 执行协议

**cwd = tomako-workspace 根目录**。必须两步，不可跳过 status：

1. **status** — 查看各仓库未提交改动、领先/落后远程、未解决冲突
2. **分析 diff** — 仅针对目标仓库（有 `--repo` 时只看这些仓库的 diff）拟定提交说明
3. **push** — 带 `-m` 执行同步、提交与推送；有未提交改动、且本地落后远程时，脚本会先 stash 本地改动，再 pull/rebase 远程提交，恢复改动后提交并 push

## 常用命令

```bash
# 1. 查看状态
./tomako-dev-skills/scripts/push-all.sh status

# 2. 提交并推送全部
./tomako-dev-skills/scripts/push-all.sh push -m "feat: 描述本次改动"

# 2b. 只提交指定仓库
./tomako-dev-skills/scripts/push-all.sh push --repo Tomako-FE -m "feat: 前端改动"

# 或环境变量
COMMIT_MSG="fix: 修复 xxx" ./tomako-dev-skills/scripts/push-all.sh push

# 预览不实际执行
DRY_RUN=1 ./tomako-dev-skills/scripts/push-all.sh push -m "..."
```

## Agent 执行模板

用户说 `$push-all` / `$提交`（全部仓库）时：

```bash
# Step 1: 状态
./tomako-dev-skills/scripts/push-all.sh status

# Step 2: 各仓库 git diff（仅对有改动的仓库）
# 在 Tomako、Tomako-portal 等目录分别 git diff，或由 status 输出判断

# Step 3: 提交推送（message 由 Agent 根据 diff 撰写）
./tomako-dev-skills/scripts/push-all.sh push -m "<根据改动拟定的提交说明>"
```

用户说「只提交前端」或指定仓库名时：

```bash
./tomako-dev-skills/scripts/push-all.sh status --repo Tomako-FE
# 分析 Tomako 前端目录 git diff
./tomako-dev-skills/scripts/push-all.sh push --repo Tomako-FE -m "<针对该仓库的提交说明>"
```

## 冲突处理（重要）

脚本**不会**自动解决冲突。

1. push 前若落后远程，会先 `fetch`，必要时 `stash` 未提交改动，再 `pull --rebase`
2. rebase/merge 冲突时：
   - 列出**冲突文件完整路径**
   - 该仓库停止 push，继续处理其他仓库
   - 若本地未提交改动已 stash，脚本会提示 stash 仍保留，避免本地改动丢失
3. stash pop 冲突时：
   - 列出**冲突文件完整路径**
   - 不自动提交、不 push；用户先人工解决冲突
4. 本地未提交改动且无冲突时：
   - 脚本按正常流程 `git add -A`、`git commit -m`、同步远程、`git push`
5. 用户解决冲突后，Agent 再次执行 status → push（可复用或更新提交说明）

冲突文件查看：

```bash
git -C <repo-path> diff --name-only --diff-filter=U
```

## 冲突说明与继续执行要求

遇到冲突时，Agent 不能只报文件名，也不能直接说“跳过 push”。必须用非技术语言说明：

1. 双方分别改了什么：例如远端新增了哪些官网工具、你本地新增了哪些工具、同一份上线记录里两边各写了什么。
2. 会影响哪里：例如官网工具入口、页面文案、在线生成入口、上线记录、Skill 规则文档、部署说明。
3. 建议怎么处理：例如两边都保留、以远端为主、以本地为主，或某一段需要用户判断。

如果用户已经给出处理选择，Agent 应继续完成当前提交推送流程：解决冲突、确认没有未解决冲突、重新检查状态、提交并推送。不要在用户已经确认方案后停在“请再次执行”这一步。

只有以下情况才可以停止等待用户：

- 用户没有给出取舍，且不同选择会丢失产品能力、文案、上线记录或 Skill 规则。
- 继续处理会覆盖用户明确要求保留的本地内容。
- 需要外部权限、密钥、发布窗口或服务器状态，当前环境无法完成。

## 跳过条件

- 工作区干净且无需 push → 无需处理
- 存在未解决冲突 → 失败并列出文件
- 未设置 upstream → 脚本使用 `git push -u origin <branch>` 建立上游并推送

## 交付前答复要求

- 各仓库：已提交 / 已 push / 无需处理 / 失败
- 失败或冲突时列出**所有冲突文件路径**与建议下一步
- 使用的提交说明原文
- 若发生过冲突，说明最终采用的处理方式，例如“两边工具都保留”“Skill 规则冲突段以远端为主，同时保留本地新增规则”

## 相关

- 拉取最新：`skills/pull-all/SKILL.md`（`$pull-all`）
