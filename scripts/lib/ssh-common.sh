# shellcheck shell=bash
# 团队统一 SSH 密钥解析（TOMAKO_SSH_KEY）。

tomako_dev_skills_resolve_ssh_key() {
  if [ -n "${TOMAKO_SSH_KEY:-}" ]; then
    if [ -f "${TOMAKO_SSH_KEY}" ]; then
      printf '%s\n' "${TOMAKO_SSH_KEY}"
      return 0
    fi
    echo "[ERROR] TOMAKO_SSH_KEY 指向的文件不存在: ${TOMAKO_SSH_KEY}" >&2
    return 1
  fi

  local candidate
  for candidate in \
    "${HOME}/.ssh/github_deploy_key" \
    "${HOME}/.ssh/id_ed25519" \
    "${HOME}/.ssh/id_rsa" \
    "${HOME}/.ssh/id_ecdsa"
  do
    if [ -f "${candidate}" ]; then
      echo "[WARN] 未设置 TOMAKO_SSH_KEY，回退使用: ${candidate}" >&2
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  echo "[ERROR] 未找到 SSH 私钥。请 export TOMAKO_SSH_KEY=~/.ssh/your_key" >&2
  return 1
}

tomako_dev_skills_ssh_cmd() {
  local ssh_key="${1:?ssh_key required}"
  shift

  ssh -i "${ssh_key}" \
    -p "${SERVER_PORT:-22}" \
    -o BatchMode=yes \
    -o ConnectTimeout=20 \
    -o StrictHostKeyChecking=accept-new \
    -o IdentitiesOnly=yes \
    "${SERVER_USER:-root}@${SERVER_HOST:-47.239.95.168}" "$@"
}

tomako_dev_skills_remote_shell() {
  local ssh_key="${1:?ssh_key required}"
  shift
  tomako_dev_skills_ssh_cmd "${ssh_key}" "set -euo pipefail; $*"
}
