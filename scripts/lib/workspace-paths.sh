# shellcheck shell=bash
# 解析 tomako-workspace（tomako-dev-skills 的父目录）内各子项目路径。
# 团队在 tomako-workspace 根目录打开 Cursor；pull/push/deploy 脚本均在此根目录下调用。

tomako_dev_skills_resolve_paths() {
  local scripts_dir="${1:?scripts_dir required}"

  # scripts_dir = tomako-workspace/tomako-dev-skills/scripts
  DEV_SKILLS_DIR="$(cd "${scripts_dir}/.." && pwd)"
  WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"

  LOCAL_FRONTEND_DIR="${LOCAL_FRONTEND_DIR:-${WORKSPACE_ROOT}/Tomako}"

  if [ -z "${LOCAL_BACKEND_DIR:-}" ]; then
    if [ -d "${WORKSPACE_ROOT}/Tomako-portal" ]; then
      LOCAL_BACKEND_DIR="${WORKSPACE_ROOT}/Tomako-portal"
    elif [ -d "${WORKSPACE_ROOT}/cibos-portal" ]; then
      LOCAL_BACKEND_DIR="${WORKSPACE_ROOT}/cibos-portal"
    else
      LOCAL_BACKEND_DIR="${WORKSPACE_ROOT}/Tomako-portal"
    fi
  fi

  LOCAL_SKILLS_OL_DIR="${LOCAL_SKILLS_OL_DIR:-${WORKSPACE_ROOT}/Skills-OL}"
  REMOTE_FRONTEND_DIR="${REMOTE_FRONTEND_DIR:-/opt/cibos/foldos}"
  REMOTE_PROJECT_DIR="${REMOTE_PROJECT_DIR:-/opt/cibos}"

  SKILLS_OL_HOST="${SKILLS_OL_HOST:-8.210.246.124}"
  SKILLS_OL_USER="${SKILLS_OL_USER:-root}"
  SKILLS_OL_PORT="${SKILLS_OL_PORT:-22}"
  SKILLS_OL_GIT_USER="${SKILLS_OL_GIT_USER:-ubuntu}"
  REMOTE_SKILLS_OL_DIR="${REMOTE_SKILLS_OL_DIR:-/home/ubuntu/Skills-OL}"
  CC_CONNECT_SERVICE="${CC_CONNECT_SERVICE:-cc-connect}"
  SKILLS_OL_GIT_BRANCH="${SKILLS_OL_GIT_BRANCH:-main}"
}

tomako_dev_skills_require_skills_ol() {
  tomako_dev_skills_resolve_paths "$@"

  if [ ! -d "${LOCAL_SKILLS_OL_DIR}" ]; then
    echo "[ERROR] 缺少 Skills-OL 目录: ${LOCAL_SKILLS_OL_DIR}" >&2
    echo "[ERROR] 请设置 LOCAL_SKILLS_OL_DIR。" >&2
    return 1
  fi

  if [ ! -d "${LOCAL_SKILLS_OL_DIR}/.git" ]; then
    echo "[ERROR] Skills-OL 不是 git 仓库: ${LOCAL_SKILLS_OL_DIR}" >&2
    return 1
  fi
}

tomako_dev_skills_require_workspace() {
  tomako_dev_skills_resolve_paths "$@"

  if [ ! -d "${LOCAL_FRONTEND_DIR}" ]; then
    echo "[ERROR] 缺少前端目录: ${LOCAL_FRONTEND_DIR}" >&2
    echo "[ERROR] 请设置 LOCAL_FRONTEND_DIR 指向 Tomako 前端目录。" >&2
    return 1
  fi

  if [ ! -d "${LOCAL_BACKEND_DIR}" ]; then
    echo "[WARN] 未检测到后端目录: ${LOCAL_BACKEND_DIR}。当前前端部署流程会继续。" >&2
  fi

  if [ ! -d "${LOCAL_SKILLS_OL_DIR}" ]; then
    echo "[WARN] 未检测到 Skills-OL 目录: ${LOCAL_SKILLS_OL_DIR}。当前前端部署流程会继续。" >&2
  fi
}

tomako_dev_skills_load_config() {
  local script_dir="${1:?script_dir required}"
  tomako_dev_skills_resolve_paths "${script_dir}"

  local config_file="${DEV_SKILLS_DIR}/config/workspace.default.env"
  if [ -f "${config_file}" ]; then
    # shellcheck disable=SC1090
    set -a
    source "${config_file}"
    set +a
  fi
}
