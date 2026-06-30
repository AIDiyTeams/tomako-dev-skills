# 本地直部署故障排查

## SSH

```bash
export TOMAKO_SSH_KEY=~/.ssh/github_deploy_key
ssh -i "$TOMAKO_SSH_KEY" root@47.239.95.168
```

| 错误 | 处理 |
| --- | --- |
| `Permission denied (publickey)` | 联系管理员将公钥加入服务器；确认 `TOMAKO_SSH_KEY` 路径正确 |
| `TOMAKO_SSH_KEY 指向的文件不存在` | 检查 export 路径 |
| `Connection timed out` | VPN / 安全组 22 端口 |

## preflight 失败

在 `Tomako/` 下：

```bash
pnpm lint && pnpm exec tsc --noEmit && NEXT_PUBLIC_SITE_URL=https://tomako.ai pnpm build
```

## 远程 build 失败

- 看 docker/podman build 最后 30 行
- 本地删文件但远程还在：`CLEAN_REMOTE=1` 重新 sync

## 与 GitHub Workflow 冲突

本地 tar 部署后若 push main，Workflow 会用 git 版本覆盖。正式发布前务必 commit + push。

## 回滚

```bash
ssh -i "$TOMAKO_SSH_KEY" root@47.239.95.168
cd /opt/cibos/foldos && git checkout <sha>
cd /opt/cibos && docker compose up -d --build frontend
```
