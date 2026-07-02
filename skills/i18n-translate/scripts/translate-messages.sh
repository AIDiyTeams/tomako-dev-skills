#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PWD}"
ARGS=()
PROJECT_ARG_INDEX=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project|--cwd)
      PROJECT_DIR="$2"
      ARGS+=("$1" "$2")
      PROJECT_ARG_INDEX="$((${#ARGS[@]} - 1))"
      shift 2
      ;;
    --project=*|--cwd=*)
      PROJECT_DIR="${1#*=}"
      ARGS+=("$1")
      PROJECT_ARG_INDEX="$((${#ARGS[@]} - 1))"
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

PROJECT_DIR="$(cd "${PROJECT_DIR}" && pwd)"

if [ -n "${PROJECT_ARG_INDEX}" ]; then
  if [[ "${ARGS[$PROJECT_ARG_INDEX]}" == *=* ]]; then
    ARGS[$PROJECT_ARG_INDEX]="${ARGS[$PROJECT_ARG_INDEX]%%=*}=${PROJECT_DIR}"
  else
    ARGS[$PROJECT_ARG_INDEX]="${PROJECT_DIR}"
  fi
else
  ARGS+=("--project" "${PROJECT_DIR}")
fi

exec pnpm --dir "${PROJECT_DIR}" exec tsx "${SCRIPT_DIR}/translate-messages.mjs" "${ARGS[@]}"
