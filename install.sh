#!/usr/bin/env bash
set -euo pipefail

# 将 tomako-dev-skills 挂载到 tomako-workspace/.cursor/skills/
# 试点：monorepo 内 tomako-dev-skills/ 目录
# 未来：git submodule add <private-repo> tomako-dev-skills

DEV_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${DEV_SKILLS_DIR}/.." && pwd)"
CURSOR_SKILLS_DIR="${WORKSPACE_ROOT}/.cursor/skills"
SKILLS_SRC_DIR="${DEV_SKILLS_DIR}/skills"

info() { echo "[install] $*"; }
warn() { echo "[install][WARN] $*"; }

if [ ! -d "${WORKSPACE_ROOT}/Tomako" ] || [ ! -d "${WORKSPACE_ROOT}/Tomako-portal" ]; then
  echo "[install][ERROR] 未检测到 tomako-workspace 结构（缺少 Tomako/ 或 Tomako-portal/）" >&2
  echo "请在 tomako-workspace 根目录运行: ./tomako-dev-skills/install.sh" >&2
  exit 1
fi

mkdir -p "${CURSOR_SKILLS_DIR}"

linked=0
for skill_path in "${SKILLS_SRC_DIR}"/*; do
  [ -d "${skill_path}" ] || continue
  [ -f "${skill_path}/SKILL.md" ] || continue

  skill_name="$(basename "${skill_path}")"
  target="${CURSOR_SKILLS_DIR}/${skill_name}"

  if [ -e "${target}" ] || [ -L "${target}" ]; then
    rm -rf "${target}"
  fi

  ln -sfn "../../tomako-dev-skills/skills/${skill_name}" "${target}"
  info "linked .cursor/skills/${skill_name} -> tomako-dev-skills/skills/${skill_name}"
  linked=$((linked + 1))
done

if [ "${linked}" -eq 0 ]; then
  warn "未发现可链接的 skill（skills/*/SKILL.md）"
  exit 1
fi

chmod +x "${DEV_SKILLS_DIR}/scripts/"*.sh 2>/dev/null || true

info "完成。已链接 ${linked} 个 skill 到 ${CURSOR_SKILLS_DIR}"
info "请确保已设置: export CIBOS_SSH_KEY=~/.ssh/your_key"
info "触发词示例: \$deploy-frontend  \$programmatic-seo"
