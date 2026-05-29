#!/usr/bin/env bash
# Open a workspace in a devcontainer with VS Code, with the workspace folder
# correctly opened — without putting any devcontainer files in the workspace.
#
#   .devcontainer/open.sh <workspace-folder> [variant]
#
#   .devcontainer/open.sh ./pontearcobaleno typescript
#   .devcontainer/open.sh ../my-lambda          # defaults to base
#
# Why this exists:
#   VS Code "Attach to Running Container" ignores devcontainer's workspaceFolder
#   and opens /home/vscode. This script brings the container up (config stays in
#   this repo, workspace stays clean) and then opens VS Code directly at
#   /workspaces/<basename> using VS Code's own attached-container URI scheme.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WS="${1:?usage: open.sh <workspace-folder> [variant]}"
VARIANT="${2:-base}"

# Resolve absolute workspace path + basename (must match workspaceFolder).
WS_ABS="$(cd "$WS" && pwd)"
WS_BASE="$(basename "$WS_ABS")"

# The base config is at the .devcontainer root; variants are in subfolders.
if [ "$VARIANT" = "base" ]; then
  CONFIG="${SCRIPT_DIR}/devcontainer.json"
else
  CONFIG="${SCRIPT_DIR}/${VARIANT}/devcontainer.json"
fi
[ -f "$CONFIG" ] || { echo "No config for variant '${VARIANT}': $CONFIG" >&2; exit 1; }

# Locate the devcontainer CLI (PATH, or the VS Code-bundled copy).
if command -v devcontainer >/dev/null 2>&1; then
  DEVCON=(devcontainer)
else
  JS=$(ls -1 "${HOME}"/.devcontainers/cli/*/package/devcontainer.js 2>/dev/null | sort -V | tail -1 || true)
  [ -n "$JS" ] || { echo "devcontainer CLI not found (npm i -g @devcontainers/cli)" >&2; exit 1; }
  DEVCON=(node "$JS")
fi

echo "▸ Bringing up '${VARIANT}' for workspace '${WS_ABS}'..."
UP_JSON=$("${DEVCON[@]}" up \
  --workspace-folder "$WS_ABS" \
  --config "$CONFIG" \
  --remove-existing-container)

CID=$(printf '%s' "$UP_JSON" | sed -n 's/.*"containerId":"\([^"]*\)".*/\1/p')
WS_FOLDER=$(printf '%s' "$UP_JSON" | sed -n 's/.*"remoteWorkspaceFolder":"\([^"]*\)".*/\1/p')
[ -n "$CID" ] || { echo "Failed to determine container id from:" >&2; echo "$UP_JSON" >&2; exit 1; }
: "${WS_FOLDER:=/workspaces/${WS_BASE}}"

# Build the attached-container folder URI exactly as VS Code does.
NAME=$(docker inspect "$CID" --format '{{.Name}}')          # e.g. /typescript-devcontainer-1
CTX=$(docker context show 2>/dev/null || echo default)
JSON=$(printf '{"containerName":"%s","settings":{"context":"%s"}}' "$NAME" "$CTX")
HEX=$(printf '%s' "$JSON" | xxd -p | tr -d '\n')
URI="vscode-remote://attached-container+${HEX}${WS_FOLDER}"

echo "▸ Opening VS Code at ${WS_FOLDER} ..."
code --folder-uri "$URI"
