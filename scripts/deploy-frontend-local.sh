#!/usr/bin/env bash
set -euo pipefail

# Tomako 前端本地直部署（无需 git push）
# Skill: tomako-dev-skills/skills/deploy-frontend/SKILL.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/workspace-paths.sh
source "${SCRIPT_DIR}/lib/workspace-paths.sh"
# shellcheck source=lib/ssh-common.sh
source "${SCRIPT_DIR}/lib/ssh-common.sh"

tomako_dev_skills_load_config "${SCRIPT_DIR}"
tomako_dev_skills_resolve_paths "${SCRIPT_DIR}"

SSH_KEY=""

DEPLOY_MODE="${DEPLOY_MODE:-auto}"
SKIP_PREFLIGHT="${SKIP_PREFLIGHT:-0}"
SKIP_SYNC="${SKIP_SYNC:-0}"
CLEAN_REMOTE="${CLEAN_REMOTE:-0}"

POD_NAME="${POD_NAME:-cibos}"
FRONTEND_CONTAINER="${FRONTEND_CONTAINER:-cibos-frontend}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-cibos-frontend}"
CANDIDATE_CONTAINER="${CANDIDATE_CONTAINER:-cibos-frontend-candidate}"
CANDIDATE_IMAGE="${CANDIDATE_IMAGE:-cibos-frontend:candidate}"
CANDIDATE_PORT="${CANDIDATE_PORT:-13000}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

usage() {
  cat <<'EOF'
用法: deploy-frontend-local.sh [command] [options]

命令:
  sync       仅同步本地 Tomako 代码到服务器
  preflight  仅本地 lint + tsc + build 验证
  deploy     仅远程构建并替换 frontend（假设代码已同步）
  full       同步 + preflight + deploy（默认）
  health     检查远程 frontend / nginx 健康状态
  logs       查看远程 frontend 日志

选项:
  --skip-preflight     跳过本地 preflight
  --skip-sync          跳过代码同步
  --clean-remote       同步前清空远程 foldos 目录（保留 .env）
  --mode auto|podman|compose
  -h, --help

环境变量:
  CIBOS_SSH_KEY        团队统一 SSH 私钥（推荐）
  SERVER_HOST          默认 47.239.95.168
  LOCAL_FRONTEND_DIR   默认 <workspace>/Tomako
EOF
}

parse_args() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  COMMAND="${1:-full}"
  shift || true

  while [ $# -gt 0 ]; do
    case "$1" in
      --skip-preflight) SKIP_PREFLIGHT=1 ;;
      --skip-sync) SKIP_SYNC=1 ;;
      --clean-remote) CLEAN_REMOTE=1 ;;
      --mode)
        shift
        DEPLOY_MODE="${1:-}"
        [ -n "${DEPLOY_MODE}" ] || error "--mode 需要参数"
        ;;
      -h|--help) usage; exit 0 ;;
      *) error "未知参数: $1" ;;
    esac
    shift || true
  done
}

require_local_frontend() {
  tomako_dev_skills_require_workspace "${SCRIPT_DIR}" || exit 1
  [ -f "${LOCAL_FRONTEND_DIR}/Containerfile" ] || error "缺少 Containerfile: ${LOCAL_FRONTEND_DIR}/Containerfile"
  SSH_KEY="$(tomako_dev_skills_resolve_ssh_key)" || exit 1
  [ -f "${SSH_KEY}" ] || error "SSH 私钥不存在: ${SSH_KEY}"
}

detect_deploy_mode() {
  if [ "${DEPLOY_MODE}" != "auto" ]; then
    info "使用指定部署模式: ${DEPLOY_MODE}"
    return
  fi

  if tomako_dev_skills_remote_shell "${SSH_KEY}" "command -v podman >/dev/null && podman pod exists '${POD_NAME}' 2>/dev/null"; then
    DEPLOY_MODE="podman"
  elif tomako_dev_skills_remote_shell "${SSH_KEY}" "command -v docker >/dev/null && [ -f '${REMOTE_PROJECT_DIR}/docker-compose.yml' ] && docker compose -f '${REMOTE_PROJECT_DIR}/docker-compose.yml' ps --services 2>/dev/null | grep -qx frontend"; then
    DEPLOY_MODE="compose"
  elif tomako_dev_skills_remote_shell "${SSH_KEY}" "command -v podman >/dev/null"; then
    DEPLOY_MODE="podman"
  elif tomako_dev_skills_remote_shell "${SSH_KEY}" "command -v docker >/dev/null && [ -f '${REMOTE_PROJECT_DIR}/docker-compose.yml' ]"; then
    DEPLOY_MODE="compose"
  else
    error "无法自动检测部署模式，请设置 DEPLOY_MODE=podman 或 compose"
  fi

  info "自动检测到部署模式: ${DEPLOY_MODE}"
}

sync_frontend() {
  info "同步 ${LOCAL_FRONTEND_DIR} -> ${SERVER_USER}@${SERVER_HOST}:${REMOTE_FRONTEND_DIR}"

  if [ "${CLEAN_REMOTE}" = "1" ]; then
    tomako_dev_skills_remote_shell "${SSH_KEY}" "
      mkdir -p '${REMOTE_FRONTEND_DIR}'
      if [ -f '${REMOTE_FRONTEND_DIR}/.env' ]; then cp '${REMOTE_FRONTEND_DIR}/.env' /tmp/foldos.env.bak; fi
      find '${REMOTE_FRONTEND_DIR}' -mindepth 1 -maxdepth 1 ! -name '.env' -exec rm -rf {} +
    "
  fi

  if command -v rsync >/dev/null && tomako_dev_skills_remote_shell "${SSH_KEY}" "command -v rsync >/dev/null"; then
    RSYNC_SSH="ssh -i ${SSH_KEY} -p ${SERVER_PORT:-22} -o BatchMode=yes -o IdentitiesOnly=yes"
    rsync -avz --delete \
      --exclude node_modules --exclude .next --exclude .git --exclude .DS_Store \
      -e "${RSYNC_SSH}" \
      "${LOCAL_FRONTEND_DIR}/" \
      "${SERVER_USER}@${SERVER_HOST}:${REMOTE_FRONTEND_DIR}/"
  else
    tar czf - \
      -C "${LOCAL_FRONTEND_DIR}" \
      --exclude node_modules --exclude .next --exclude .git --exclude .DS_Store . \
    | tomako_dev_skills_ssh_cmd "${SSH_KEY}" "mkdir -p '${REMOTE_FRONTEND_DIR}' && cd '${REMOTE_FRONTEND_DIR}' && tar xzf -"
  fi

  if [ "${CLEAN_REMOTE}" = "1" ]; then
    tomako_dev_skills_remote_shell "${SSH_KEY}" "[ -f /tmp/foldos.env.bak ] && mv /tmp/foldos.env.bak '${REMOTE_FRONTEND_DIR}/.env' || true"
  fi

  info "代码同步完成"
}

run_preflight() {
  info "本地 preflight: lint + tsc + production build"
  (
    cd "${LOCAL_FRONTEND_DIR}"
    pnpm lint
    pnpm exec tsc --noEmit
    NODE_ENV=production \
    NEXT_PUBLIC_SITE_URL="${NEXT_PUBLIC_SITE_URL}" \
    NEXT_PUBLIC_API_BASE_URL="${NEXT_PUBLIC_API_BASE_URL}" \
    NEXT_PUBLIC_MOCK_API="${NEXT_PUBLIC_MOCK_API}" \
      pnpm build
  )
  info "本地 preflight 通过"
}

deploy_podman() {
  tomako_dev_skills_remote_shell "${SSH_KEY}" "
    cd '${REMOTE_FRONTEND_DIR}'
    podman build \
      --build-arg NEXT_PUBLIC_SITE_URL='${NEXT_PUBLIC_SITE_URL}' \
      --build-arg NEXT_PUBLIC_MOCK_API='${NEXT_PUBLIC_MOCK_API}' \
      --build-arg NEXT_PUBLIC_API_BASE_URL='${NEXT_PUBLIC_API_BASE_URL}' \
      -t '${CANDIDATE_IMAGE}' .
    podman rm -f '${CANDIDATE_CONTAINER}' 2>/dev/null || true
    podman run -d --name '${CANDIDATE_CONTAINER}' \
      -e NODE_ENV=production \
      -e NEXT_PUBLIC_API_BASE_URL='${NEXT_PUBLIC_API_BASE_URL}' \
      -e NEXT_PUBLIC_MOCK_API='${NEXT_PUBLIC_MOCK_API}' \
      -e NEXT_PUBLIC_SITE_URL='${NEXT_PUBLIC_SITE_URL}' \
      -e PORT=3000 -e HOSTNAME=0.0.0.0 \
      -p 127.0.0.1:${CANDIDATE_PORT}:3000 \
      '${CANDIDATE_IMAGE}'
    STATUS=000
    for i in \$(seq 1 20); do
      STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:${CANDIDATE_PORT}/ 2>/dev/null || echo 000)
      echo \"Candidate health \${i}: \${STATUS}\"
      case \"\${STATUS}\" in 200|307|308) break ;; esac
      sleep 2
    done
    case \"\${STATUS}\" in 200|307|308) ;; *)
      podman logs --tail 80 '${CANDIDATE_CONTAINER}' || true
      podman rm -f '${CANDIDATE_CONTAINER}' 2>/dev/null || true
      exit 1 ;; esac
    podman rm -f '${CANDIDATE_CONTAINER}'
    podman tag '${CANDIDATE_IMAGE}' '${FRONTEND_IMAGE}:latest'
    podman rm -f '${FRONTEND_CONTAINER}' 2>/dev/null || true
    podman run -d --pod '${POD_NAME}' --name '${FRONTEND_CONTAINER}' \
      -e NODE_ENV=production \
      -e NEXT_PUBLIC_API_BASE_URL='${NEXT_PUBLIC_API_BASE_URL}' \
      -e NEXT_PUBLIC_MOCK_API='${NEXT_PUBLIC_MOCK_API}' \
      -e NEXT_PUBLIC_SITE_URL='${NEXT_PUBLIC_SITE_URL}' \
      -e PORT=3000 -e HOSTNAME=0.0.0.0 \
      '${FRONTEND_IMAGE}:latest'
  "
}

deploy_compose() {
  tomako_dev_skills_remote_shell "${SSH_KEY}" "cd '${REMOTE_PROJECT_DIR}' && docker compose up -d --build frontend"
}

deploy_frontend() {
  detect_deploy_mode
  case "${DEPLOY_MODE}" in
    podman) deploy_podman ;;
    compose) deploy_compose ;;
    *) error "未知 DEPLOY_MODE: ${DEPLOY_MODE}" ;;
  esac
}

check_health() {
  detect_deploy_mode
  tomako_dev_skills_remote_shell "${SSH_KEY}" "
    if [ '${DEPLOY_MODE}' = 'compose' ]; then
      docker compose -f '${REMOTE_PROJECT_DIR}/docker-compose.yml' ps frontend || true
    else
      podman ps --filter name='${FRONTEND_CONTAINER}' || true
    fi
    curl -s -o /dev/null -w 'nginx => %{http_code}\n' http://127.0.0.1/ || true
    curl -s -o /dev/null -w 'tomako.ai => %{http_code}\n' https://tomako.ai/ 2>/dev/null || true
  "
}

show_logs() {
  detect_deploy_mode
  if [ "${DEPLOY_MODE}" = "compose" ]; then
    tomako_dev_skills_remote_shell "${SSH_KEY}" "cd '${REMOTE_PROJECT_DIR}' && docker compose logs --tail 100 frontend"
  else
    tomako_dev_skills_remote_shell "${SSH_KEY}" "podman logs --tail 100 '${FRONTEND_CONTAINER}'"
  fi
}

main() {
  parse_args "$@"
  case "${COMMAND}" in
    sync|preflight|deploy|full|health|logs) require_local_frontend ;;
    *) usage; exit 1 ;;
  esac

  info "workspace: ${WORKSPACE_ROOT}"
  info "target: ${SERVER_USER}@${SERVER_HOST}:${REMOTE_FRONTEND_DIR}"
  info "SSH: ${SSH_KEY}"

  case "${COMMAND}" in
    sync) sync_frontend ;;
    preflight) run_preflight ;;
    deploy) deploy_frontend; check_health ;;
    full)
      [ "${SKIP_SYNC}" = "1" ] || sync_frontend
      [ "${SKIP_PREFLIGHT}" = "1" ] || run_preflight
      deploy_frontend
      check_health
      ;;
    health) check_health ;;
    logs) show_logs ;;
  esac
}

main "$@"
