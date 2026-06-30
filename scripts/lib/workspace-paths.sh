# shellcheck shell=bash
# 解析 tomako-dev-skills 父目录内各子项目路径。
# 父目录名称和同级项目结构自定；具体脚本只校验自己实际需要的目录。

tomako_dev_skills_resolve_paths() {
  local scripts_dir="${1:?scripts_dir required}"

  # scripts_dir = tomako-dev-skills/scripts
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
