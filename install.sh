#!/usr/bin/env bash
set -euo pipefail

# 将 tomako-dev-skills 挂载到其父目录内各 Agent 平台的 skills 目录。
DEV_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"
SKILLS_SRC_DIR="${DEV_SKILLS_DIR}/skills"

SKILL_TARGET_DIRS=(
  ".cursor/skills"
  ".claude/skills"
  ".codex/skills"
  ".agents/skills"
  "Tomako/.codex/skills"
  "Tomako/.agents/skills"
  "Tomako-FE/.codex/skills"
  "Tomako-FE/.agents/skills"
)

DEV_SKILLS_TARGET_DIRS=(
  ".cursor/skills"
  ".claude/skills"
  ".codex/skills"
  ".agents/skills"
)

INSTALL_VERBOSE="${INSTALL_VERBOSE:-0}"

linked=0
skipped=0
pruned=0
progress_done=0
progress_total=0

INSTALL_WARNINGS=()
INSTALL_ERRORS=()

info()  {
  if [ "${INSTALL_VERBOSE}" = "1" ]; then
    echo "[install] $*"
  fi
}

warn_collect() {
  INSTALL_WARNINGS+=("$*")
  if [ "${INSTALL_VERBOSE}" = "1" ]; then
    echo "[install][WARN] $*" >&2
  fi
}
error_exit() { INSTALL_ERRORS+=("$*"); echo "[install][ERROR] $*" >&2; exit 1; }

progress_tick() {
  progress_done=$((progress_done + 1))
  if [ "${INSTALL_VERBOSE}" = "1" ]; then
    return 0
  fi
  if [ ! -t 1 ]; then
    return 0
  fi
  local width=36 filled pct bar empty i
  width=36
  if [ "${progress_total}" -le 0 ]; then
    return 0
  fi
  filled=$((progress_done * width / progress_total))
  pct=$((progress_done * 100 / progress_total))
  bar=""
  empty=""
  for ((i=0; i<filled; i++)); do bar+="#"; done
  for ((i=filled; i<width; i++)); do empty+="-"; done
  printf "\r[install] [%s%s] %3d%% (%d/%d)" "${bar}" "${empty}" "${pct}" "${progress_done}" "${progress_total}"
}

progress_finish() {
  if [ "${INSTALL_VERBOSE}" = "1" ]; then
    return 0
  fi
  if [ -t 1 ]; then
    echo
  else
    echo " 完成"
  fi
}

count_install_tasks() {
  local rel_dir base_dir target_dir skill_path skill_name n=0

  for rel_dir in "${SKILL_TARGET_DIRS[@]}"; do
    case "${rel_dir}" in
      Tomako/*)
        [ -d "${WORKSPACE_ROOT}/Tomako" ] || continue
        ;;
      Tomako-FE/*)
        [ -d "${WORKSPACE_ROOT}/Tomako-FE" ] || continue
        ;;
    esac
    for skill_path in "${SKILLS_SRC_DIR}"/*; do
      [ -d "${skill_path}" ] || continue
      [ -f "${skill_path}/SKILL.md" ] || continue
      n=$((n + 1))
    done
    n=$((n + 1)) # prune pass
  done

  for rel_dir in "${DEV_SKILLS_TARGET_DIRS[@]}"; do
    for skill_path in "${SKILLS_SRC_DIR}"/*; do
      [ -d "${skill_path}" ] || continue
      [ -f "${skill_path}/SKILL.md" ] || continue
      n=$((n + 1))
    done
    n=$((n + 1))
  done

  progress_total="${n}"
}

print_trigger_words() {
  local title trigger dim reset ok
  if [ -t 1 ]; then
    ok=$'\033[1;32m'
    title=$'\033[1;36m'
    trigger=$'\033[1;33m'
    dim=$'\033[2m'
    reset=$'\033[0m'
  else
    ok='' title='' trigger='' dim='' reset=''
  fi

  echo ""
  printf "%b✓ 安装完成%b\n" "${ok}" "${reset}"
  printf "%b可用触发词%b（在 tomako-workspace 根目录打开 Cursor 后使用）：\n\n" "${title}" "${reset}"
  printf "  %b\$programmatic-seo / \$pseo%b     %b程序化 SEO 工具页%b\n" "${trigger}" "${reset}" "${dim}" "${reset}"
  printf "  %b\$deploy-frontend / \$部署前端%b   %b前端直部署（168）%b\n" "${trigger}" "${reset}" "${dim}" "${reset}"
  printf "  %b\$deploy-skills-ol / \$部署skills%b  %bSkills-OL → cc-connect（124）%b\n" "${trigger}" "${reset}" "${dim}" "${reset}"
  printf "  %b\$pull-all / \$拉取 / \$拉取代码%b   %b拉取全部仓库%b\n" "${trigger}" "${reset}" "${dim}" "${reset}"
  printf "  %b\$push-all / \$提交 / \$提交代码%b   %b提交并推送全部仓库%b\n" "${trigger}" "${reset}" "${dim}" "${reset}"
  echo ""
}

print_install_summary() {
  local w

  if [ "${#INSTALL_ERRORS[@]}" -gt 0 ]; then
    echo "[install] 安装失败" >&2
    for w in "${INSTALL_ERRORS[@]}"; do
      echo "  ✗ ${w}" >&2
    done
    exit 1
  fi

  if [ "${#INSTALL_WARNINGS[@]}" -eq 0 ]; then
    print_trigger_words
    return 0
  fi

  echo "[install] 完成（有 ${#INSTALL_WARNINGS[@]} 条警告）" >&2
  for w in "${INSTALL_WARNINGS[@]}"; do
    echo "  ! ${w}" >&2
  done
  echo "处理警告后重新运行: ./tomako-dev-skills/install.sh" >&2
  exit 1
}

if [ ! -d "${SKILLS_SRC_DIR}" ]; then
  error_exit "未找到 skills 来源目录: ${SKILLS_SRC_DIR}"
fi

if [ ! -d "${WORKSPACE_ROOT}/Tomako" ]; then
  info "未检测到同级 Tomako/"
fi

if [ ! -d "${WORKSPACE_ROOT}/Tomako-portal" ] && [ ! -d "${WORKSPACE_ROOT}/cibos-portal" ]; then
  info "未检测到同级 Tomako-portal/"
fi

link_skill() {
  local target_dir="$1"
  local skill_name="$2"
  local target="${target_dir}/${skill_name}"
  local source="${SKILLS_SRC_DIR}/${skill_name}"

  if [ -L "${target}" ]; then
    local current_link
    current_link="$(readlink "${target}")"
    if [ "${current_link}" = "${source}" ]; then
      linked=$((linked + 1))
      progress_tick
      return 0
    fi
    warn_collect "替换错误 symlink: ${target}"
    rm "${target}"
  elif [ -e "${target}" ]; then
    if diff -qr "${source}" "${target}" >/dev/null 2>&1; then
      warn_collect "替换内容一致的旧副本: ${target}"
      rm -rf "${target}"
    else
      warn_collect "跳过有差异的本地副本: ${target}（请先迁移改动并删除该目录）"
      skipped=$((skipped + 1))
      progress_tick
      return 1
    fi
  fi

  ln -sfn "${source}" "${target}"
  linked=$((linked + 1))
  progress_tick
}

ensure_skills_parent_dir() {
  local target_dir="$1"

  if [ -L "${target_dir}" ]; then
    warn_collect "移除旧版整目录 symlink: ${target_dir}"
    rm "${target_dir}"
  fi

  mkdir -p "${target_dir}"
}

prune_stale_skills() {
  local target_dir="$1"
  local entry name source

  [ -d "${target_dir}" ] || return 0

  for entry in "${target_dir}"/*; do
    [ -L "${entry}" ] || continue
    name="$(basename "${entry}")"
    source="${SKILLS_SRC_DIR}/${name}"
    if [ ! -f "${source}/SKILL.md" ]; then
      rm "${entry}"
      pruned=$((pruned + 1))
      info "移除过时 symlink: ${entry}"
    fi
  done
  progress_tick
}

install_skills_under() {
  local base_dir="$1"
  local rel_dir="$2"
  local target_dir="${base_dir}/${rel_dir}"

  case "${rel_dir}" in
    Tomako/*)
      [ -d "${WORKSPACE_ROOT}/Tomako" ] || return 0
      ;;
    Tomako-FE/*)
      [ -d "${WORKSPACE_ROOT}/Tomako-FE" ] || return 0
      ;;
  esac

  ensure_skills_parent_dir "${target_dir}"

  for skill_path in "${SKILLS_SRC_DIR}"/*; do
    [ -d "${skill_path}" ] || continue
    [ -f "${skill_path}/SKILL.md" ] || continue
    link_skill "${target_dir}" "$(basename "${skill_path}")" || true
  done

  prune_stale_skills "${target_dir}"
}

count_install_tasks

[ "${INSTALL_VERBOSE}" = "1" ] || printf "[install] 正在安装 skills…\n"

for rel_dir in "${SKILL_TARGET_DIRS[@]}"; do
  install_skills_under "${WORKSPACE_ROOT}" "${rel_dir}"
done

for rel_dir in "${DEV_SKILLS_TARGET_DIRS[@]}"; do
  install_skills_under "${DEV_SKILLS_DIR}" "${rel_dir}"
done

progress_finish

if [ "${linked}" -eq 0 ]; then
  error_exit "未成功链接任何 skill"
fi

chmod +x "${DEV_SKILLS_DIR}/scripts/"*.sh 2>/dev/null || true

if [ "${skipped}" -gt 0 ]; then
  warn_collect "共跳过 ${skipped} 个有差异的本地副本"
fi

print_install_summary
