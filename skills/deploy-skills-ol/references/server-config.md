# 124 cc-connect / Skills-OL 服务器

## SSH

```bash
export TOMAKO_SSH_KEY=~/.ssh/github_deploy_key
ssh -i "$TOMAKO_SSH_KEY" root@8.210.246.124
```

部署脚本默认使用 `SKILLS_OL_HOST` / `SKILLS_OL_USER`，与前端 168 分离。

## 路径与服务

| 项 | 值 |
| --- | --- |
| Skills-OL 目录 | `/home/ubuntu/Skills-OL` |
| git 操作用户 | `ubuntu` |
| systemd 服务 | `cc-connect` |
| Bridge WebSocket | `:9810` |

## 部署流程（脚本自动执行）

```bash
su - ubuntu -c 'cd ~/Skills-OL && git fetch && git pull origin main'
su - ubuntu -c 'cd ~/Skills-OL && npm install'   # 有 package.json 时
systemctl restart cc-connect
```

## 与 Git 的关系

- **不会** rsync 本地未提交代码
- 必须先 `git push` Skills-OL，再在 124 上 pull
- 本地有未 push 提交时，`full` 默认中止（`--force` 可跳过警告）

## 故障排查

| 现象 | 检查 |
| --- | --- |
| pull 失败 | 124 上 ubuntu 用户的 GitHub 部署密钥 / 仓库权限 |
| Agent 仍跑旧 skill | 是否 restart cc-connect；`deploy-skills-ol.sh status` 对比 commit |
| npm install 失败 | Node 版本、网络；SSH 登录手动执行 |

完整架构见 `Tomako-portal/deploy/SERVERS.md`。
