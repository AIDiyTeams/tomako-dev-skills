# shellcheck shell=bash
# tomako-workspace 内 git 仓库的发现与公共 git 操作。
# WORKSPACE_ROOT = 含 Tomako/、tomako-dev-skills/ 等同级目录的工作区根（常见目录名 tomako-workspace）。

tomako_dev_skills_git_backend_repo_name() {
  if [ -d "${WORKSPACE_ROOT}/Tomako-portal" ]; then
    echo "Tomako-portal"
  elif [ -d "${WORKSPACE_ROOT}/cibos-portal" ]; then
    echo "cibos-portal"
  else
    echo "Tomako-portal"
  fi
}

tomako_dev_skills_git_repo_names() {
  local extra

  echo "tomako-dev-skills"
  echo "Tomako"
  tomako_dev_skills_git_backend_repo_name
  echo "Skills-OL"

  # 可选：EXTRA_GIT_REPOS="Tomako2 cc-connect" 纳入默认 pull/push-all 范围
  extra="${EXTRA_GIT_REPOS:-}"
  extra="${extra//,/ }"
  for extra in ${extra}; do
    [ -n "${extra}" ] || continue
    echo "${extra}"
  done
}

tomako_dev_skills_git_workspace_child_path() {
  local name="$1"
  local path="${WORKSPACE_ROOT}/${name}"

  if [ -d "${path}/.git" ]; then
    echo "${path}"
    return 0
  fi
  return 1
}

tomako_dev_skills_git_normalize_repo_name() {
  local input="$1"
  local lower backend

  lower="$(printf '%s' "${input}" | tr '[:upper:]' '[:lower:]')"
  backend="$(tomako_dev_skills_git_backend_repo_name)"

  case "${lower}" in
    tomako-dev-skills|dev-skills) echo "tomako-dev-skills" ;;
    tomako|frontend) echo "Tomako" ;;
    tomako-portal|cibos-portal|portal|backend) echo "${backend}" ;;
    skills-ol|skillsol) echo "Skills-OL" ;;
    *)
      case "${input}" in
        tomako-dev-skills|Tomako|Tomako-portal|cibos-portal|Skills-OL) echo "${input}" ;;
        *)
          if tomako_dev_skills_git_workspace_child_path "${input}" >/dev/null; then
            echo "${input}"
            return 0
          fi
          return 1
          ;;
      esac
      ;;
  esac
}

tomako_dev_skills_git_repo_filter_add() {
  local raw="$1"
  local normalized

  normalized="$(tomako_dev_skills_git_normalize_repo_name "${raw}")" || {
    local backend_name
    backend_name="$(tomako_dev_skills_git_backend_repo_name)"
    echo "[ERROR] 未知仓库: ${raw}" >&2
    echo "[ERROR] 默认可用: tomako-dev-skills, Tomako, ${backend_name}, Skills-OL" >&2
    echo "[ERROR] 别名: frontend, portal/backend, dev-skills" >&2
    echo "[ERROR] 或 tomako-workspace 下任意含 .git 的子目录名（如 Tomako2）" >&2
    return 1
  }
  if [ -z "${REPO_FILTER}" ]; then
    REPO_FILTER="${normalized}"
  else
    REPO_FILTER="${REPO_FILTER} ${normalized}"
  fi
}

tomako_dev_skills_foreach_repo() {
  local callback="$1"
  local name path token

  if [ -n "${REPO_FILTER// }" ]; then
    for token in ${REPO_FILTER}; do
      name="${token}"
      path="$(tomako_dev_skills_git_repo_path "${name}")" || continue
      [ -d "${path}" ] || continue
      if [ ! -d "${path}/.git" ]; then
        continue
      fi
      "${callback}" "${name}" "${path}"
    done
    return 0
  fi

  for name in $(tomako_dev_skills_git_repo_names); do
    [ -n "${name}" ] || continue
    path="$(tomako_dev_skills_git_repo_path "${name}")" || continue
    [ -d "${path}" ] || continue
    if [ ! -d "${path}/.git" ]; then
      continue
    fi
    "${callback}" "${name}" "${path}"
  done
}

tomako_dev_skills_git_repo_path() {
  local name="$1"
  local path

  case "${name}" in
    tomako-dev-skills) echo "${DEV_SKILLS_DIR}" ;;
    Tomako) echo "${LOCAL_FRONTEND_DIR}" ;;
    Tomako-portal|cibos-portal) echo "${LOCAL_BACKEND_DIR}" ;;
    Skills-OL) echo "${LOCAL_SKILLS_OL_DIR}" ;;
    *)
      if path="$(tomako_dev_skills_git_workspace_child_path "${name}")"; then
        echo "${path}"
        return 0
      fi
      return 1
      ;;
  esac
}

tomako_dev_skills_git_repo_filter_validate() {
  local name path token

  if [ -z "${REPO_FILTER// }" ]; then
    return 0
  fi

  for token in ${REPO_FILTER}; do
    name="${token}"
    path="$(tomako_dev_skills_git_repo_path "${name}")" || continue
    if [ -d "${path}/.git" ]; then
      return 0
    fi
  done

  echo "[ERROR] --repo 指定的仓库在本地不存在或不是 git 仓库: ${REPO_FILTER}" >&2
  return 1
}

tomako_dev_skills_git_dirty_files() {
  local repo_path="$1"
  git -C "${repo_path}" status --porcelain 2>/dev/null
}

tomako_dev_skills_git_has_dirty() {
  local repo_path="$1"
  [ -n "$(tomako_dev_skills_git_dirty_files "${repo_path}")" ]
}

tomako_dev_skills_git_conflict_files() {
  local repo_path="$1"
  git -C "${repo_path}" diff --name-only --diff-filter=U 2>/dev/null
}

tomako_dev_skills_git_current_branch() {
  local repo_path="$1"
  git -C "${repo_path}" symbolic-ref --quiet --short HEAD 2>/dev/null \
    || git -C "${repo_path}" rev-parse --short HEAD 2>/dev/null
}

tomako_dev_skills_git_upstream_ref() {
  local repo_path="$1"
  local branch
  branch="$(tomako_dev_skills_git_current_branch "${repo_path}")" || return 1
  git -C "${repo_path}" rev-parse --abbrev-ref "${branch}@{upstream}" 2>/dev/null
}

tomako_dev_skills_git_ahead_behind() {
  local repo_path="$1"
  local upstream
  upstream="$(tomako_dev_skills_git_upstream_ref "${repo_path}")" || {
    echo "no-upstream"
    return 0
  }
  git -C "${repo_path}" rev-list --left-right --count HEAD..."${upstream}" 2>/dev/null \
    | awk '{print $1 " " $2}'
}
