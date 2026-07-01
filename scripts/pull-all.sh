#!/usr/bin/env bash
set -euo pipefail

# 拉取 Tomako workspace 内各仓库的远程最新代码
# Skill: tomako-dev-skills/skills/pull-all/SKILL.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/workspace-paths.sh
source "${SCRIPT_DIR}/lib/workspace-paths.sh"
# shellcheck source=lib/git-repos.sh
source "${SCRIPT_DIR}/lib/git-repos.sh"

tomako_dev_skills_load_config "${SCRIPT_DIR}"
tomako_dev_skills_resolve_paths "${SCRIPT_DIR}"

FILTER_RAW="${REPO_FILTER:-}"
REPO_FILTER=""
AUTOSTASH="${AUTOSTASH:-1}"
REBASE="${REBASE:-1}"
FAILED=0
PULLED=0
SKIPPED=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
repo_hdr() { echo -e "${CYAN}━━ ${1} ━━${NC}"; }

usage() {
  cat <<'EOF'
用法: pull-all.sh [command] [options]

命令:
  pull      拉取各仓库远程最新代码（默认）
  status    显示各仓库分支与落后/领先远程的提交数

选项:
  -r, --repo NAME   只处理指定仓库（可重复）；别名见 push-all.sh --help
  --autostash       有未提交改动时自动 stash 再 pull，成功后 pop（默认）
  --no-autostash    有未提交改动时不自动 stash，直接失败并列出文件
  --no-rebase    使用 merge 而非 rebase 拉取
  -h, --help

环境变量:
  AUTOSTASH=1    等同 --autostash（默认）
  AUTOSTASH=0    等同 --no-autostash
  REBASE=0       等同 --no-rebase
  REPO_FILTER=...  空格分隔的仓库名（等同多个 --repo）
EOF
}

apply_repo_filter_env() {
  if [ -z "${REPO_FILTER// }" ] && [ -n "${FILTER_RAW}" ]; then
    local token
    for token in ${FILTER_RAW}; do
      tomako_dev_skills_git_repo_filter_add "${token}" || exit 1
    done
  fi
}

parse_args() {
  COMMAND="${1:-pull}"
  shift || true

  while [ $# -gt 0 ]; do
    case "$1" in
      pull|status) COMMAND="$1" ;;
      -r|--repo)
        shift
        [ -n "${1:-}" ] || { error "-r/--repo 需要参数"; exit 1; }
        tomako_dev_skills_git_repo_filter_add "${1}" || exit 1
        ;;
      --autostash) AUTOSTASH=1 ;;
      --no-autostash) AUTOSTASH=0 ;;
      --no-rebase) REBASE=0 ;;
      -h|--help) usage; exit 0 ;;
      *) error "未知参数: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

print_conflict_files_full() {
  local path="$1"
  local file
  tomako_dev_skills_git_conflict_files "${path}" | while IFS= read -r file; do
    [ -n "${file}" ] || continue
    printf '    %s/%s\n' "${path}" "${file}"
  done
}

print_repo_status() {
  local name="$1"
  local path="$2"
  local branch upstream ahead behind dirty

  branch="$(tomako_dev_skills_git_current_branch "${path}")"
  repo_hdr "${name} (${path#${WORKSPACE_ROOT}/})"
  echo "  分支: ${branch:-unknown}"

  if upstream="$(tomako_dev_skills_git_upstream_ref "${path}")"; then
  read -r ahead behind <<<"$(tomako_dev_skills_git_ahead_behind "${path}")"
    echo "  上游: ${upstream}"
    echo "  领先 ${ahead:-0} / 落后 ${behind:-0} 个提交"
  else
    echo "  上游: 未设置"
  fi

  if tomako_dev_skills_git_has_dirty "${path}"; then
    echo "  工作区: 有未提交改动"
    tomako_dev_skills_git_dirty_files "${path}" | sed 's/^/    /'
  else
    echo "  工作区: 干净"
  fi
  echo
}

do_pull_repo() {
  local name="$1"
  local path="$2"
  local branch pull_args=() stash_made=0 conflicts

  repo_hdr "${name} (${path#${WORKSPACE_ROOT}/})"

  if ! branch="$(tomako_dev_skills_git_current_branch "${path}")"; then
    warn "无法识别当前分支，跳过"
    SKIPPED=$((SKIPPED + 1))
    echo
    return 0
  fi

  if tomako_dev_skills_git_has_dirty "${path}"; then
    if [ "${AUTOSTASH}" = "1" ]; then
      info "检测到未提交改动，执行 stash..."
      git -C "${path}" stash push -u -m "pull-all autostash $(date +%Y%m%d-%H%M%S)"
      stash_made=1
    else
      error "有未提交改动，且 AUTOSTASH=0；为避免覆盖本地代码，本仓库失败"
      tomako_dev_skills_git_dirty_files "${path}" | sed 's/^/    /'
      FAILED=$((FAILED + 1))
      echo
      return 0
    fi
  fi

  if ! git -C "${path}" fetch origin --prune; then
    error "fetch 失败"
    FAILED=$((FAILED + 1))
    echo
    return 0
  fi

  if [ "${REBASE}" = "1" ]; then
    pull_args=(pull --rebase origin "${branch}")
  else
    pull_args=(pull origin "${branch}")
  fi

  if git -C "${path}" "${pull_args[@]}"; then
    info "已更新到最新"
    PULLED=$((PULLED + 1))
  else
    error "pull 失败"
    conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
    if [ -n "${conflicts}" ]; then
      error "冲突文件（需人工解决后重新执行 pull-all 或 push-all）："
      print_conflict_files_full "${path}"
    fi
    FAILED=$((FAILED + 1))
  fi

  if [ "${stash_made}" = "1" ]; then
    if git -C "${path}" stash pop; then
      info "已恢复 stash"
    else
      conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
      if [ -n "${conflicts}" ]; then
        error "恢复本地改动时产生冲突，请人工解决："
        print_conflict_files_full "${path}"
      else
        warn "stash pop 失败，请手动 git stash list / git stash pop"
      fi
      FAILED=$((FAILED + 1))
    fi
  fi

  echo
}

cmd_status() {
  tomako_dev_skills_git_repo_filter_validate || exit 1
  info "Workspace: ${WORKSPACE_ROOT}"
  if [ -n "${REPO_FILTER// }" ]; then
    info "限定仓库: ${REPO_FILTER}"
  fi
  tomako_dev_skills_foreach_repo print_repo_status
}

cmd_pull() {
  tomako_dev_skills_git_repo_filter_validate || exit 1
  info "Workspace: ${WORKSPACE_ROOT}"
  if [ -n "${REPO_FILTER// }" ]; then
    info "限定仓库: ${REPO_FILTER}"
  fi
  info "模式: fetch + pull $([ "${REBASE}" = "1" ] && echo --rebase || echo --no-rebase), autostash=${AUTOSTASH}"
  tomako_dev_skills_foreach_repo do_pull_repo

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info "完成: 更新 ${PULLED} 个仓库, 跳过 ${SKIPPED} 个, 失败 ${FAILED} 个"
  [ "${FAILED}" -eq 0 ]
}

parse_args "$@"
apply_repo_filter_env
case "${COMMAND}" in
  status) cmd_status ;;
  pull) cmd_pull ;;
  *) usage; exit 1 ;;
esac
