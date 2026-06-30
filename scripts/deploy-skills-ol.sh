#!/usr/bin/env bash
set -euo pipefail

# Skills-OL 部署到 cc-connect 服务器（124）：git pull + npm install + restart
# Skill: tomako-dev-skills/skills/deploy-skills-ol/SKILL.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/workspace-paths.sh
source "${SCRIPT_DIR}/lib/workspace-paths.sh"
# shellcheck source=lib/ssh-common.sh
source "${SCRIPT_DIR}/lib/ssh-common.sh"

tomako_dev_skills_load_config "${SCRIPT_DIR}"
tomako_dev_skills_resolve_paths "${SCRIPT_DIR}"

SSH_KEY=""
SKIP_PREFLIGHT="${SKIP_PREFLIGHT:-0}"
SKIP_NPM="${SKIP_NPM:-0}"
SKIP_RESTART="${SKIP_RESTART:-0}"
FORCE_DEPLOY="${FORCE_DEPLOY:-0}"
JSON_OUTPUT="${JSON_OUTPUT:-0}"

DEPLOY_STATUS="unknown"
REMOTE_BEFORE=""
REMOTE_AFTER=""
NPM_STATUS="skipped"
RESTART_STATUS="skipped"
CC_STATUS="unknown"
SYNC_WITH_LOCAL="unknown"
DEPLOY_REPORT_FILE=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; DEPLOY_STATUS="failed"; write_deploy_report; exit 1; }

usage() {
  cat <<'EOF'
用法: deploy-skills-ol.sh [command] [options]

命令:
  status     对比本地与远端 Skills-OL commit、服务状态
  report     显示上次部署结果（读取 .cache/deploy-skills-ol-last.json）
  preflight  检查 SSH、未 push 提交、远端连通性
  pull       仅在 124 上 git pull（+ 按需 npm install）
  restart    仅重启 cc-connect
  full       preflight + pull + restart + health（默认）
  health     检查远端 git 版本与 cc-connect 状态

选项:
  --json              以 JSON 输出部署结果（full/status 结束时）
  --skip-preflight    跳过 preflight（含未 push 警告）
  --skip-npm          跳过 npm install
  --skip-restart      pull 后不重启 cc-connect
  --force             有未 push 提交时仍继续部署
  -h, --help

部署结果默认写入: tomako-dev-skills/.cache/deploy-skills-ol-last.json
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
      --json) JSON_OUTPUT=1 ;;
      --skip-preflight) SKIP_PREFLIGHT=1 ;;
      --skip-npm) SKIP_NPM=1 ;;
      --skip-restart) SKIP_RESTART=1 ;;
      --force) FORCE_DEPLOY=1 ;;
      -h|--help) usage; exit 0 ;;
      *) error "未知参数: $1" ;;
    esac
    shift || true
  done
}

skills_ol_ssh() {
  tomako_dev_skills_ssh_cmd_target "${SSH_KEY}" "${SKILLS_OL_USER}" "${SKILLS_OL_HOST}" "${SKILLS_OL_PORT}" "$@"
}

skills_ol_remote() {
  tomako_dev_skills_remote_shell_target "${SSH_KEY}" "${SKILLS_OL_USER}" "${SKILLS_OL_HOST}" "${SKILLS_OL_PORT}" "$@"
}

require_local_skills_ol() {
  tomako_dev_skills_require_skills_ol "${SCRIPT_DIR}" || exit 1
  SSH_KEY="$(tomako_dev_skills_resolve_ssh_key)" || exit 1
  [ -f "${SSH_KEY}" ] || error "SSH 私钥不存在: ${SSH_KEY}"
}

local_branch() {
  git -C "${LOCAL_SKILLS_OL_DIR}" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "detached"
}

local_head() {
  git -C "${LOCAL_SKILLS_OL_DIR}" rev-parse HEAD
}

local_head_short() {
  git -C "${LOCAL_SKILLS_OL_DIR}" rev-parse --short HEAD
}

local_upstream_ahead() {
  local branch upstream
  branch="$(local_branch)"
  [ "${branch}" != "detached" ] || { echo "0"; return; }
  upstream="$(git -C "${LOCAL_SKILLS_OL_DIR}" rev-parse --abbrev-ref "${branch}@{upstream}" 2>/dev/null || true)"
  [ -n "${upstream}" ] || { echo "0"; return; }
  git -C "${LOCAL_SKILLS_OL_DIR}" rev-list --count "${upstream}..HEAD" 2>/dev/null || echo "0"
}

remote_head_full() {
  skills_ol_remote "
    su - '${SKILLS_OL_GIT_USER}' -c 'cd \"${REMOTE_SKILLS_OL_DIR}\" && git rev-parse HEAD'
  " | tr -d '[:space:]'
}

remote_head_short() {
  skills_ol_remote "
    su - '${SKILLS_OL_GIT_USER}' -c 'cd \"${REMOTE_SKILLS_OL_DIR}\" && git rev-parse --short HEAD'
  " | tr -d '[:space:]'
}

remote_cc_status() {
  skills_ol_remote "systemctl is-active '${CC_CONNECT_SERVICE}' 2>/dev/null || echo inactive" | tr -d '[:space:]'
}

capture_remote_state() {
  REMOTE_AFTER="$(remote_head_full)"
  CC_STATUS="$(remote_cc_status)"
  if [ "$(local_head)" = "${REMOTE_AFTER}" ]; then
    SYNC_WITH_LOCAL="yes"
  else
    SYNC_WITH_LOCAL="no"
  fi
}

write_deploy_report() {
  DEPLOY_REPORT_FILE="${DEPLOY_REPORT_FILE:-${DEV_SKILLS_DIR}/.cache/deploy-skills-ol-last.json}"
  local ts local_short remote_short local_full
  mkdir -p "$(dirname "${DEPLOY_REPORT_FILE}")"
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local_full="$(local_head 2>/dev/null || echo "")"
  local_short="$(local_head_short 2>/dev/null || echo "")"
  remote_short="$(printf '%s' "${REMOTE_AFTER}" | cut -c1-7)"

  if [ "${JSON_OUTPUT}" = "1" ]; then
    cat >"${DEPLOY_REPORT_FILE}" <<EOF
{
  "status": "${DEPLOY_STATUS}",
  "timestamp": "${ts}",
  "server": "${SKILLS_OL_USER}@${SKILLS_OL_HOST}",
  "remote_dir": "${REMOTE_SKILLS_OL_DIR}",
  "branch": "${SKILLS_OL_GIT_BRANCH}",
  "local_commit": "${local_full}",
  "local_commit_short": "${local_short}",
  "remote_commit_before": "${REMOTE_BEFORE}",
  "remote_commit_after": "${REMOTE_AFTER}",
  "remote_commit_short": "${remote_short}",
  "in_sync_with_local": "${SYNC_WITH_LOCAL}",
  "npm_install": "${NPM_STATUS}",
  "cc_connect_restart": "${RESTART_STATUS}",
  "cc_connect_status": "${CC_STATUS}"
}
EOF
    cat "${DEPLOY_REPORT_FILE}"
    return 0
  fi

  cat >"${DEPLOY_REPORT_FILE}" <<EOF
status=${DEPLOY_STATUS}
timestamp=${ts}
server=${SKILLS_OL_USER}@${SKILLS_OL_HOST}
remote_dir=${REMOTE_SKILLS_OL_DIR}
branch=${SKILLS_OL_GIT_BRANCH}
local_commit=${local_short}
remote_before=${REMOTE_BEFORE:0:7}
remote_after=${remote_short}
in_sync_with_local=${SYNC_WITH_LOCAL}
npm_install=${NPM_STATUS}
cc_connect_restart=${RESTART_STATUS}
cc_connect_status=${CC_STATUS}
EOF
}

print_deploy_report() {
  write_deploy_report >/dev/null

  if [ "${JSON_OUTPUT}" = "1" ]; then
    cat "${DEPLOY_REPORT_FILE}"
    return 0
  fi

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}Skills-OL 部署结果${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "  状态:        ${DEPLOY_STATUS}"
  echo "  服务器:      ${SKILLS_OL_USER}@${SKILLS_OL_HOST}"
  echo "  本地 commit: $(local_head_short) ($(local_branch))"
  echo "  部署前远端:  ${REMOTE_BEFORE:0:7}"
  echo "  部署后远端:  ${REMOTE_AFTER:0:7}"
  echo "  与本地一致:  ${SYNC_WITH_LOCAL}"
  echo "  npm install: ${NPM_STATUS}"
  echo "  重启服务:    ${RESTART_STATUS}"
  echo "  cc-connect:  ${CC_STATUS}"
  echo "  报告文件:    ${DEPLOY_REPORT_FILE#${WORKSPACE_ROOT}/}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

cmd_report() {
  if [ ! -f "${DEPLOY_REPORT_FILE}" ]; then
    error "尚无部署记录，请先执行 deploy-skills-ol.sh full"
  fi
  if [ "${JSON_OUTPUT}" = "1" ] || head -1 "${DEPLOY_REPORT_FILE}" | grep -q '^{'; then
    cat "${DEPLOY_REPORT_FILE}"
  else
    cat "${DEPLOY_REPORT_FILE}"
  fi
}

remote_pull() {
  info "远端 git pull: ${SKILLS_OL_GIT_USER}@${SKILLS_OL_HOST}:${REMOTE_SKILLS_OL_DIR} (${SKILLS_OL_GIT_BRANCH})"
  skills_ol_remote "
    [ -d '${REMOTE_SKILLS_OL_DIR}/.git' ] || { echo '远端不是 git 仓库' >&2; exit 1; }
    su - '${SKILLS_OL_GIT_USER}' -c '
      set -euo pipefail
      cd \"${REMOTE_SKILLS_OL_DIR}\"
      git fetch origin --prune
      git pull origin \"${SKILLS_OL_GIT_BRANCH}\"
    '
  "
  capture_remote_state
  info "远端当前 commit: $(remote_head_short)"
}

remote_npm_install() {
  if [ "${SKIP_NPM}" = "1" ]; then
    NPM_STATUS="skipped"
    warn "跳过 npm install"
    return 0
  fi
  if [ ! -f "${LOCAL_SKILLS_OL_DIR}/package.json" ]; then
    NPM_STATUS="not_needed"
    info "本地无 package.json，跳过 npm install"
    return 0
  fi
  info "远端 npm install（如有新依赖）"
  skills_ol_remote "
    su - '${SKILLS_OL_GIT_USER}' -c '
      set -euo pipefail
      cd \"${REMOTE_SKILLS_OL_DIR}\"
      if [ -f package.json ]; then
        npm install
      fi
    '
  "
  NPM_STATUS="done"
}

restart_cc_connect() {
  if [ "${SKIP_RESTART}" = "1" ]; then
    RESTART_STATUS="skipped"
    warn "跳过 cc-connect 重启"
    CC_STATUS="$(remote_cc_status)"
    return 0
  fi
  info "重启 ${CC_CONNECT_SERVICE}"
  skills_ol_remote "
    systemctl restart '${CC_CONNECT_SERVICE}'
    sleep 2
    systemctl is-active --quiet '${CC_CONNECT_SERVICE}'
  "
  RESTART_STATUS="done"
  CC_STATUS="$(remote_cc_status)"
  info "${CC_CONNECT_SERVICE} 运行中"
}

cmd_status() {
  require_local_skills_ol
  REMOTE_AFTER="$(remote_head_full)"
  CC_STATUS="$(remote_cc_status)"
  capture_remote_state
  DEPLOY_STATUS="status"

  info "本地: ${LOCAL_SKILLS_OL_DIR} @ $(local_head_short) ($(local_branch))"
  local ahead
  ahead="$(local_upstream_ahead)"
  [ "${ahead}" -eq 0 ] || warn "领先 origin ${ahead} 个提交（尚未 push）"
  info "远端: ${REMOTE_AFTER:0:7} | cc-connect: ${CC_STATUS}"
  print_deploy_report
}

run_preflight() {
  require_local_skills_ol
  info "SSH 连通: ${SKILLS_OL_USER}@${SKILLS_OL_HOST}"
  skills_ol_ssh "echo ok" >/dev/null

  local ahead
  ahead="$(local_upstream_ahead)"
  if [ "${ahead}" -gt 0 ]; then
    if [ "${FORCE_DEPLOY}" = "1" ] || [ "${SKIP_PREFLIGHT}" = "1" ]; then
      warn "本地领先 origin ${ahead} 个提交；远端 pull 不会包含这些改动"
    else
      error "本地有 ${ahead} 个未 push 提交。请先 push Skills-OL，或使用 --force"
    fi
  fi

  if [ -n "$(git -C "${LOCAL_SKILLS_OL_DIR}" status --porcelain)" ]; then
    warn "本地 Skills-OL 有未提交改动（远端 pull 不会包含）"
  fi

  info "preflight 通过"
}

cmd_health() {
  require_local_skills_ol
  REMOTE_AFTER="$(remote_head_full)"
  CC_STATUS="$(remote_cc_status)"
  info "远端 Skills-OL: ${REMOTE_AFTER:0:7} @ ${REMOTE_SKILLS_OL_DIR}"
  skills_ol_remote "
    systemctl status '${CC_CONNECT_SERVICE}' --no-pager -n 0 || true
    ss -lntp 2>/dev/null | grep -E ':9810|:9820' || true
  "
}

cmd_full() {
  require_local_skills_ol
  REMOTE_BEFORE="$(remote_head_full)"
  [ "${SKIP_PREFLIGHT}" = "1" ] || run_preflight
  remote_pull
  remote_npm_install
  restart_cc_connect
  cmd_health >/dev/null 2>&1 || true

  if [ "${SYNC_WITH_LOCAL}" = "yes" ] && [ "${CC_STATUS}" = "active" ]; then
    DEPLOY_STATUS="success"
  else
    DEPLOY_STATUS="success_with_warnings"
  fi

  print_deploy_report
}

main() {
  parse_args "$@"
  info "workspace: ${WORKSPACE_ROOT}"
  info "target: ${SKILLS_OL_USER}@${SKILLS_OL_HOST}:${REMOTE_SKILLS_OL_DIR}"

  case "${COMMAND}" in
    status) cmd_status ;;
    report) cmd_report ;;
    preflight) run_preflight ;;
    pull)
      require_local_skills_ol
      REMOTE_BEFORE="$(remote_head_full)"
      remote_pull
      remote_npm_install
      DEPLOY_STATUS="pulled"
      print_deploy_report
      ;;
    restart)
      require_local_skills_ol
      restart_cc_connect
      DEPLOY_STATUS="restarted"
      print_deploy_report
      ;;
    health) cmd_health ;;
    full) cmd_full ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
