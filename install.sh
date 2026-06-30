#!/usr/bin/env bash
set -euo pipefail

# 将 tomako-dev-skills 挂载到其父目录内各 Agent 平台的 skills 目录。
# 父目录名称和同级项目结构自定；安装 skill 链接不要求同时存在 Tomako/ 或后端目录。
# canonical 来源：本仓库 skills/
#
# 平台目录：
#   Cursor:       .cursor/skills/
#   Claude Code:  .claude/skills/
#   Codex:        .codex/skills/  与  .agents/skills/（cc-connect Codex agent 亦扫描后者）
#   子项目入口:    Tomako/.codex/skills/ 与 Tomako/.agents/skills/（当同事在 Tomako/ 内打开 Agent 工具时使用）
#   本仓库内:      tomako-dev-skills/.cursor/skills/（当直接在 tomako-dev-skills 目录打开 Cursor 时）
#
DEV_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"
SKILLS_SRC_DIR="${DEV_SKILLS_DIR}/skills"

# 相对 tomako-workspace 根目录
SKILL_TARGET_DIRS=(
  ".cursor/skills"
  ".claude/skills"
  ".codex/skills"
  ".agents/skills"
  "Tomako/.codex/skills"
  "Tomako/.agents/skills"
)

# 相对 tomako-dev-skills 自身（仅 Cursor/Claude 常见）
DEV_SKILLS_TARGET_DIRS=(
  ".cursor/skills"
  ".claude/skills"
  ".codex/skills"
  ".agents/skills"
)

info() { echo "[install] $*"; }
warn() { echo "[install][WARN] $*"; }
error() { echo "[install][ERROR] $*" >&2; }

if [ ! -d "${SKILLS_SRC_DIR}" ]; then
  echo "[install][ERROR] 未找到 skills 来源目录: ${SKILLS_SRC_DIR}" >&2
  echo "请从 tomako-dev-skills 仓库内运行 install.sh" >&2
  exit 1
fi

if [ ! -d "${WORKSPACE_ROOT}/Tomako" ]; then
  warn "未检测到同级 Tomako/。skill 仍会安装；需要操作前端时可在对应 skill 中设置 LOCAL_FRONTEND_DIR。"
fi

if [ ! -d "${WORKSPACE_ROOT}/Tomako-portal" ] && [ ! -d "${WORKSPACE_ROOT}/cibos-portal" ]; then
  warn "未检测到同级 Tomako-portal/ 或 cibos-portal/。skill 仍会安装；需要操作后端时可设置 LOCAL_BACKEND_DIR。"
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
      return 0
    fi
    warn "替换错误 symlink: ${target} -> ${current_link}"
    rm "${target}"
  elif [ -e "${target}" ]; then
    if diff -qr "${source}" "${target}" >/dev/null 2>&1; then
      warn "替换内容一致的旧副本: ${target}"
      rm -rf "${target}"
    else
      warn "跳过有差异的本地副本: ${target}"
      warn "请先比较并迁移需要保留的改动，再删除该目录后重新运行 install.sh"
      return 1
    fi
  fi

  ln -sfn "${source}" "${target}"
}

ensure_skills_parent_dir() {
  local target_dir="$1"

  if [ -L "${target_dir}" ]; then
    warn "移除旧版整目录 symlink: ${target_dir} -> $(readlink "${target_dir}")"
    rm "${target_dir}"
  fi

  mkdir -p "${target_dir}"
}

linked=0
skipped=0
pruned=0

prune_stale_skills() {
  local target_dir="$1"
  local entry name source

  [ -d "${target_dir}" ] || return 0

  for entry in "${target_dir}"/*; do
    [ -L "${entry}" ] || continue
    name="$(basename "${entry}")"
    source="${SKILLS_SRC_DIR}/${name}"
    if [ ! -f "${source}/SKILL.md" ]; then
      warn "移除过时 symlink: ${entry}"
      rm "${entry}"
      pruned=$((pruned + 1))
    fi
  done
}

install_skills_under() {
  local base_dir="$1"
  local rel_dir="$2"
  local target_dir="${base_dir}/${rel_dir}"

  if [[ "${rel_dir}" == Tomako/* ]] && [ ! -d "${WORKSPACE_ROOT}/Tomako" ]; then
    warn "跳过 ${rel_dir}: 未检测到同级 Tomako/"
    return 0
  fi

  ensure_skills_parent_dir "${target_dir}"

  for skill_path in "${SKILLS_SRC_DIR}"/*; do
    [ -d "${skill_path}" ] || continue
    [ -f "${skill_path}/SKILL.md" ] || continue

    skill_name="$(basename "${skill_path}")"
    if link_skill "${target_dir}" "${skill_name}"; then
      info "linked ${target_dir#${WORKSPACE_ROOT}/}/${skill_name} -> skills/${skill_name}"
      linked=$((linked + 1))
    else
      skipped=$((skipped + 1))
    fi
  done

  prune_stale_skills "${target_dir}"
}

for rel_dir in "${SKILL_TARGET_DIRS[@]}"; do
  install_skills_under "${WORKSPACE_ROOT}" "${rel_dir}"
done

for rel_dir in "${DEV_SKILLS_TARGET_DIRS[@]}"; do
  install_skills_under "${DEV_SKILLS_DIR}" "${rel_dir}"
done

if [ "${linked}" -eq 0 ]; then
  error "未成功链接任何 skill。请检查是否存在有差异的本地副本。"
  exit 1
fi

chmod +x "${DEV_SKILLS_DIR}/scripts/"*.sh 2>/dev/null || true

if [ "${skipped}" -gt 0 ]; then
  warn "发现 ${skipped} 个有差异的本地副本，已跳过，避免覆盖同事改动。"
  warn "处理方式：先把需要保留的改动迁移到 ${SKILLS_SRC_DIR#${WORKSPACE_ROOT}/}/，再删除本地副本并重新运行 install.sh。"
fi

info "完成。已链接/确认 ${linked} 条 symlink，移除 ${pruned} 个过时链接，跳过 ${skipped} 个有差异的本地副本。"
info "推荐在 tomako-workspace 根目录打开 Cursor；若只打开 tomako-dev-skills 子目录，skills 已同步到 tomako-dev-skills/.cursor/skills/"
info "触发词: \$push-all / \$提交  |  \$pull-all / \$拉取  |  \$deploy-frontend"
