# 168 生产服务器配置

## SSH

团队统一使用环境变量 `CIBOS_SSH_KEY`：

```bash
export CIBOS_SSH_KEY=~/.ssh/github_deploy_key
ssh -i "$CIBOS_SSH_KEY" root@47.239.95.168
```

未设置时，脚本按顺序探测：`github_deploy_key` → `id_ed25519` → `id_rsa` → `id_ecdsa`。

## 服务器

| 项 | 值 |
| --- | --- |
| IP | `47.239.95.168` |
| SSH 用户 | `root` |
| 对外域名 | `https://tomako.ai` |

## 目录结构

```
/opt/cibos/
├── foldos/                 # Tomako 前端
├── cibos-portal/           # 后端
├── docker-compose.yml      # Docker Compose 模式
└── data/
```

## 部署模式

脚本 `DEPLOY_MODE=auto` 自动检测 Podman pod 或 Docker Compose。

详见 `Tomako-portal/deploy/SERVERS.md`。

## 同步

服务器通常无 rsync，默认 **tar 管道**。本地删文件后需：

```bash
CLEAN_REMOTE=1 ./tomako-dev-skills/scripts/deploy-frontend-local.sh sync
```
