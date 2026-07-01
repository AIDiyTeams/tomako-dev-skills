#!/usr/bin/env bash
set -euo pipefail

# 提交并推送 Tomako workspace 内各仓库的本地改动
# Skill: tomako-dev-skills/skills/push-all/SKILL.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/workspace-paths.sh
source "${SCRIPT_DIR}/lib/workspace-paths.sh"
# shellcheck source=lib/git-repos.sh
source "${SCRIPT_DIR}/lib/git-repos.sh"

tomako_dev_skills_load_config "${SCRIPT_DIR}"
tomako_dev_skills_resolve_paths "${SCRIPT_DIR}"

FILTER_RAW="${REPO_FILTER:-}"
REPO_FILTER=""
COMMIT_MSG="${COMMIT_MSG:-}"
DRY_RUN="${DRY_RUN:-0}"
REBASE="${REBASE:-1}"
FAILED=0
PUSHED=0
COMMITTED=0
SKIPPED=0

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
repo_hdr() { echo -e "${CYAN}━━ ${1} ━━${NC}"; }

usage() {
  cat <<'EOF'
用法: push-all.sh [command] [options]

命令:
  status    显示各仓库未提交改动与领先/落后远程情况
  push      提交本地改动并 push（默认需 -m 提交说明）

选项:
  -m, --message MSG   提交说明（也可用环境变量 COMMIT_MSG）
  -r, --repo NAME     只处理指定仓库（可重复）；别名见下方
  --dry-run           只显示将要执行的操作，不实际 commit/push
  --no-rebase         pull 时使用 merge 而非 rebase
  -h, --help

仓库与别名:
  tomako-dev-skills (dev-skills)
  Tomako (tomako, frontend)
  Tomako-portal / cibos-portal (portal, backend)
  Skills-OL

冲突处理:
  若 rebase/merge/stash pop 产生冲突，脚本会列出冲突文件并停止该仓库的 push。
  人工解决冲突后，再次执行 push-all push 即可继续。

环境变量:
  COMMIT_MSG=...   提交说明
  DRY_RUN=1        等同 --dry-run
  REPO_FILTER=...  空格分隔的仓库名（等同多个 --repo）
EOF
}

parse_args() {
  COMMAND="${1:-}"
  shift || true

  while [ $# -gt 0 ]; do
    case "$1" in
      status|push) COMMAND="$1" ;;
      -m|--message)
        shift
        COMMIT_MSG="${1:-}"
        [ -n "${COMMIT_MSG}" ] || { error "-m/--message 需要参数"; exit 1; }
        ;;
      -r|--repo)
        shift
        [ -n "${1:-}" ] || { error "-r/--repo 需要参数"; exit 1; }
        tomako_dev_skills_git_repo_filter_add "${1}" || exit 1
        ;;
      --dry-run) DRY_RUN=1 ;;
      --no-rebase) REBASE=0 ;;
      -h|--help) usage; exit 0 ;;
      *) error "未知参数: $1"; usage; exit 1 ;;
    esac
    shift
  done

  [ -n "${COMMAND}" ] || COMMAND="push"
}

apply_repo_filter_env() {
  if [ -z "${REPO_FILTER// }" ] && [ -n "${FILTER_RAW}" ]; then
    local token
    for token in ${FILTER_RAW}; do
      tomako_dev_skills_git_repo_filter_add "${token}" || exit 1
    done
  fi
}

print_repo_status() {
  local name="$1"
  local path="$2"
  local branch upstream ahead behind

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
    echo "  未提交改动:"
    tomako_dev_skills_git_dirty_files "${path}" | sed 's/^/    /'
  else
    echo "  工作区: 干净"
  fi

  conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
  if [ -n "${conflicts}" ]; then
    echo "  未解决冲突:"
    echo "${conflicts}" | sed 's/^/    /'
  fi
  echo
}

print_conflict_files_full() {
  local path="$1"
  local file
  tomako_dev_skills_git_conflict_files "${path}" | while IFS= read -r file; do
    [ -n "${file}" ] || continue
    printf '    %s/%s\n' "${path}" "${file}"
  done
}

repo_needs_push() {
  local path="$1"
  tomako_dev_skills_git_has_dirty "${path}" && return 0
  local ahead
  read -r ahead _ <<<"$(tomako_dev_skills_git_ahead_behind "${path}" 2>/dev/null || echo "0 0")"
  [ "${ahead:-0}" -gt 0 ]
}

do_push_repo() {
  local name="$1"
  local path="$2"
  local branch msg ahead behind conflicts upstream has_dirty stash_made=0 push_args=()

  repo_hdr "${name} (${path#${WORKSPACE_ROOT}/})"

  conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
  if [ -n "${conflicts}" ]; then
    error "存在未解决冲突，请先人工处理:"
    print_conflict_files_full "${path}"
    FAILED=$((FAILED + 1))
    echo
    return 0
  fi

  if ! branch="$(tomako_dev_skills_git_current_branch "${path}")"; then
    warn "无法识别当前分支，跳过"
    SKIPPED=$((SKIPPED + 1))
    echo
    return 0
  fi

  has_dirty=0
  if tomako_dev_skills_git_has_dirty "${path}"; then
    has_dirty=1
  fi

  if upstream="$(tomako_dev_skills_git_upstream_ref "${path}")"; then
    if [ "${DRY_RUN}" = "1" ]; then
      info "[dry-run] git fetch origin --prune"
    elif ! git -C "${path}" fetch origin --prune; then
      error "fetch 失败"
      FAILED=$((FAILED + 1))
      echo
      return 0
    fi
    read -r ahead behind <<<"$(tomako_dev_skills_git_ahead_behind "${path}" 2>/dev/null || echo "0 0")"
  else
    upstream=""
    ahead=0
    behind=0
  fi

  if [ "${has_dirty}" = "0" ] && [ "${ahead:-0}" -eq 0 ]; then
    info "无改动且无需处理"
    SKIPPED=$((SKIPPED + 1))
    echo
    return 0
  fi

  if [ "${behind:-0}" -gt 0 ]; then
    if [ "${DRY_RUN}" = "1" ]; then
      if [ "${has_dirty}" = "1" ]; then
        info "[dry-run] git stash push -u -m \"push-all autostash ...\""
      fi
      info "[dry-run] git pull $([ "${REBASE}" = "1" ] && echo --rebase || echo --no-rebase) origin ${branch}"
      if [ "${has_dirty}" = "1" ]; then
        info "[dry-run] git stash pop"
      fi
    else
      if [ "${has_dirty}" = "1" ]; then
        info "检测到未提交改动；先 stash，避免同步远程时覆盖本地代码..."
        git -C "${path}" stash push -u -m "push-all autostash $(date +%Y%m%d-%H%M%S)"
        stash_made=1
      fi

      info "落后远程 ${behind} 个提交，先同步..."
      if [ "${REBASE}" = "1" ]; then
        if ! git -C "${path}" pull --rebase origin "${branch}"; then
          error "rebase 失败"
          conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
          if [ -n "${conflicts}" ]; then
            error "冲突文件（请人工解决后再次执行 push-all）："
            print_conflict_files_full "${path}"
          fi
          if [ "${stash_made}" = "1" ]; then
            warn "本地未提交改动仍保存在 stash 中，请解决 rebase 后手动 git stash pop"
          fi
          FAILED=$((FAILED + 1))
          echo
          return 0
        fi
      else
        if ! git -C "${path}" pull origin "${branch}"; then
          error "merge 失败"
          conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
          if [ -n "${conflicts}" ]; then
            error "冲突文件（请人工解决后再次执行 push-all）："
            print_conflict_files_full "${path}"
          fi
          if [ "${stash_made}" = "1" ]; then
            warn "本地未提交改动仍保存在 stash 中，请解决 merge 后手动 git stash pop"
          fi
          FAILED=$((FAILED + 1))
          echo
          return 0
        fi
      fi

      if [ "${stash_made}" = "1" ]; then
        if git -C "${path}" stash pop; then
          info "已恢复本地未提交改动"
        else
          error "恢复本地未提交改动时产生冲突，请人工解决："
          conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
          if [ -n "${conflicts}" ]; then
            print_conflict_files_full "${path}"
          fi
          FAILED=$((FAILED + 1))
          echo
          return 0
        fi
      fi
    fi
  fi

  has_dirty=0
  if tomako_dev_skills_git_has_dirty "${path}"; then
    has_dirty=1
  fi

  if [ "${has_dirty}" = "1" ]; then
    msg="${COMMIT_MSG}"
    if [ "${DRY_RUN}" = "1" ]; then
      info "[dry-run] git add -A && git commit -m \"${msg}\""
    else
      git -C "${path}" add -A
      if ! git -C "${path}" commit -m "${msg}"; then
        conflicts="$(tomako_dev_skills_git_conflict_files "${path}")"
        if [ -n "${conflicts}" ]; then
          error "commit 前仍存在冲突文件："
          print_conflict_files_full "${path}"
        else
          error "commit 失败"
        fi
        FAILED=$((FAILED + 1))
        echo
        return 0
      fi
      info "已提交"
      COMMITTED=$((COMMITTED + 1))
    fi
  fi

  if [ -n "${upstream}" ]; then
    read -r ahead behind <<<"$(tomako_dev_skills_git_ahead_behind "${path}" 2>/dev/null || echo "0 0")"
  else
    ahead=1
    behind=0
  fi
  if [ "${ahead:-0}" -eq 0 ] && [ "${has_dirty}" = "0" ]; then
    info "已与远程同步，无需 push"
    SKIPPED=$((SKIPPED + 1))
    echo
    return 0
  fi

  if [ "${DRY_RUN}" = "1" ]; then
    if [ -n "${upstream}" ]; then
      info "[dry-run] git push origin ${branch}"
    else
      info "[dry-run] git push -u origin ${branch}"
    fi
    PUSHED=$((PUSHED + 1))
  else
    if [ -n "${upstream}" ]; then
      push_args=(push origin "${branch}")
    else
      push_args=(push -u origin "${branch}")
      info "未设置上游分支，将执行 git push -u origin ${branch}"
    fi

    if git -C "${path}" "${push_args[@]}"; then
      info "已 push 到 origin/${branch}"
      PUSHED=$((PUSHED + 1))
    else
      error "push 失败"
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

cmd_push() {
  if [ -z "${COMMIT_MSG}" ]; then
    error "push 需要提交说明，请使用 -m \"...\" 或设置 COMMIT_MSG"
    echo
    echo "建议流程:"
    echo "  1. ./tomako-dev-skills/scripts/push-all.sh status"
    echo "  2. 根据 diff 拟定提交说明"
    echo "  3. ./tomako-dev-skills/scripts/push-all.sh push -m \"你的提交说明\""
    echo "  单仓库: ./tomako-dev-skills/scripts/push-all.sh push --repo Tomako -m \"...\""
    exit 1
  fi

  tomako_dev_skills_git_repo_filter_validate || exit 1

  info "Workspace: ${WORKSPACE_ROOT}"
  if [ -n "${REPO_FILTER// }" ]; then
    info "限定仓库: ${REPO_FILTER}"
  fi
  info "提交说明: ${COMMIT_MSG}"
  tomako_dev_skills_foreach_repo do_push_repo

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  info "完成: 提交 ${COMMITTED} 个, push ${PUSHED} 个, 无需处理/跳过 ${SKIPPED} 个, 失败 ${FAILED} 个"
  if [ "${FAILED}" -gt 0 ]; then
    warn "有仓库失败或存在冲突，解决后请再次执行 push-all push"
  fi
  [ "${FAILED}" -eq 0 ]
}

parse_args "$@"
apply_repo_filter_env
case "${COMMAND}" in
  status) cmd_status ;;
  push) cmd_push ;;
  *) usage; exit 1 ;;
esac
