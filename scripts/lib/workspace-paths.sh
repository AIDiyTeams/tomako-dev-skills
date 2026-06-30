# shellcheck shell=bash
# 解析 tomako-workspace 内各子项目路径。

tomako_dev_skills_resolve_paths() {
  local scripts_dir="${1:?scripts_dir required}"

  # scripts_dir = tomako-dev-skills/scripts
  DEV_SKILLS_DIR="$(cd "${scripts_dir}/.." && pwd)"
  WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"

  LOCAL_FRONTEND_DIR="${LOCAL_FRONTEND_DIR:-${WORKSPACE_ROOT}/Tomako}"
  LOCAL_BACKEND_DIR="${LOCAL_BACKEND_DIR:-${WORKSPACE_ROOT}/Tomako-portal}"
  LOCAL_SKILLS_OL_DIR="${LOCAL_SKILLS_OL_DIR:-${WORKSPACE_ROOT}/Skills-OL}"
  REMOTE_FRONTEND_DIR="${REMOTE_FRONTEND_DIR:-/opt/cibos/foldos}"
  REMOTE_PROJECT_DIR="${REMOTE_PROJECT_DIR:-/opt/cibos}"
}

tomako_dev_skills_require_workspace() {
  tomako_dev_skills_resolve_paths "$@"

  local missing=0
  for dir in "${LOCAL_FRONTEND_DIR}" "${LOCAL_BACKEND_DIR}" "${LOCAL_SKILLS_OL_DIR}"; do
    if [ ! -d "${dir}" ]; then
      echo "[ERROR] 缺少 workspace 子目录: ${dir}" >&2
      missing=1
    fi
  done

  if [ "${missing}" -ne 0 ]; then
    echo "[ERROR] 请在 tomako-workspace 根目录下使用，或设置 LOCAL_*_DIR 环境变量。" >&2
    return 1
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
