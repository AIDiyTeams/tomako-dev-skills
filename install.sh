#!/usr/bin/env bash
set -euo pipefail

# 将 tomako-dev-skills 挂载到其父目录内各 Agent 平台的 skills 目录。
# 父目录名称和同级项目结构自定；安装 skill 链接不要求同时存在 Tomako/ 或后端目录。
# canonical 来源：本仓库 skills/
#
# 平台目录（均在本仓库父目录）：
#   Cursor:       .cursor/skills/
#   Claude Code:  .claude/skills/
#   Codex:        .codex/skills/  与  .agents/skills/（cc-connect Codex agent 亦扫描后者）
#
DEV_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"
SKILLS_SRC_DIR="${DEV_SKILLS_DIR}/skills"

SKILL_TARGET_DIRS=(
  ".cursor/skills"
  ".claude/skills"
  ".codex/skills"
  ".agents/skills"
)

info() { echo "[install] $*"; }
warn() { echo "[install][WARN] $*"; }

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

  if [ -e "${target}" ] || [ -L "${target}" ]; then
    rm -rf "${target}"
  fi

  ln -sfn "${source}" "${target}"
}

ensure_skills_parent_dir() {
  local rel_dir="$1"
  local target_dir="${WORKSPACE_ROOT}/${rel_dir}"

  if [ -L "${target_dir}" ]; then
    warn "移除旧版整目录 symlink: ${rel_dir} -> $(readlink "${target_dir}")"
    rm "${target_dir}"
  fi

  mkdir -p "${target_dir}"
}

linked=0

for rel_dir in "${SKILL_TARGET_DIRS[@]}"; do
  ensure_skills_parent_dir "${rel_dir}"
  target_dir="${WORKSPACE_ROOT}/${rel_dir}"

  for skill_path in "${SKILLS_SRC_DIR}"/*; do
    [ -d "${skill_path}" ] || continue
    [ -f "${skill_path}/SKILL.md" ] || continue

    skill_name="$(basename "${skill_path}")"
    link_skill "${target_dir}" "${skill_name}"
    source_display="${SKILLS_SRC_DIR#${WORKSPACE_ROOT}/}/${skill_name}"
    info "linked ${rel_dir}/${skill_name} -> ${source_display}"
    linked=$((linked + 1))
  done
done

if [ "${linked}" -eq 0 ]; then
  warn "未发现可链接的 skill（skills/*/SKILL.md）"
  exit 1
fi

skills_per_dir=$((linked / ${#SKILL_TARGET_DIRS[@]}))

chmod +x "${DEV_SKILLS_DIR}/scripts/"*.sh 2>/dev/null || true

info "完成。已链接 ${skills_per_dir} 个 skill × ${#SKILL_TARGET_DIRS[@]} 个平台目录（共 ${linked} 条 symlink）"
info "适用: Cursor | Claude Code | Codex（请在安装目录的父目录打开项目；本脚本不强制同级项目名称）"
info "请确保已设置: export TOMAKO_SSH_KEY=~/.ssh/your_key"
info "触发词示例: \$deploy-frontend  \$programmatic-seo"
