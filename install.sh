#!/usr/bin/env bash
set -euo pipefail

# 将 tomako-dev-skills 挂载到 tomako-workspace 内各 Agent 平台的 skills 目录。
# canonical 来源：tomako-dev-skills/skills/
#
# 平台目录（均在 workspace 根目录）：
#   Cursor:       .cursor/skills/
#   Claude Code:  .claude/skills/
#   Codex:        .codex/skills/  与  .agents/skills/（cc-connect Codex agent 亦扫描后者）
#
# 未来：git submodule add <private-repo> tomako-dev-skills

DEV_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"
SKILLS_SRC_DIR="${DEV_SKILLS_DIR}/skills"

# 相对路径：从 */skills/<name> 指向 tomako-dev-skills/skills/<name>
SKILL_LINK_RELPATH="../../tomako-dev-skills/skills"

SKILL_TARGET_DIRS=(
  ".cursor/skills"
  ".claude/skills"
  ".codex/skills"
  ".agents/skills"
)

info() { echo "[install] $*"; }
warn() { echo "[install][WARN] $*"; }

if [ ! -d "${WORKSPACE_ROOT}/Tomako" ] || [ ! -d "${WORKSPACE_ROOT}/Tomako-portal" ]; then
  echo "[install][ERROR] 未检测到 tomako-workspace 结构（缺少 Tomako/ 或 Tomako-portal/）" >&2
  echo "请在 tomako-workspace 根目录运行: ./tomako-dev-skills/install.sh" >&2
  exit 1
fi

link_skill() {
  local target_dir="$1"
  local skill_name="$2"
  local target="${target_dir}/${skill_name}"

  if [ -e "${target}" ] || [ -L "${target}" ]; then
    rm -rf "${target}"
  fi

  ln -sfn "${SKILL_LINK_RELPATH}/${skill_name}" "${target}"
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
    info "linked ${rel_dir}/${skill_name} -> tomako-dev-skills/skills/${skill_name}"
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
info "适用: Cursor | Claude Code | Codex（请在 tomako-workspace 根目录打开项目）"
info "请确保已设置: export CIBOS_SSH_KEY=~/.ssh/your_key"
info "触发词示例: \$deploy-frontend  \$programmatic-seo"
