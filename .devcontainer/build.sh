#!/usr/bin/env bash
# Build the base image. Run this once before opening any language devcontainer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure .env exists and variant symlinks are in place (same logic as init.sh).
# This allows running build.sh without having opened VS Code first.
"${SCRIPT_DIR}/init.sh"

# Load the generated env so BASE_IMAGE is available without re-exporting manually.
# shellcheck disable=SC1090
set -a; source "${SCRIPT_DIR}/.env"; set +a

echo "Building base image: ${BASE_IMAGE}"
docker build \
  --tag "${BASE_IMAGE}" \
  --file "${SCRIPT_DIR}/Dockerfile" \
  "${SCRIPT_DIR}"

echo ""
echo "Base image ready : ${BASE_IMAGE}"
echo "Claude persistence: ${CLAUDE_PERSIST_HOST_DIR}"
echo ""
echo "Open the repo in VS Code and 'Reopen in Container' (defaults to base),"
echo "or pick a language variant via 'Dev Containers: Reopen in Container'."
