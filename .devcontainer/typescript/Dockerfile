ARG BASE_IMAGE=aws-lambda-base:latest
FROM ${BASE_IMAGE}

# Node.js LTS is already provided by the base image (required for CDK).
# This variant adds the TypeScript compiler and common Lambda authoring tools.

# Global TypeScript toolchain. Must run as root — npm's global prefix
# (/usr/lib/node_modules) is root-owned, same as the base image's CDK install.
#   typescript  — the tsc compiler
#   ts-node     — run .ts directly (handler experiments, scripts)
#   esbuild     — fast bundler used by CDK NodejsFunction and SAM esbuild builds
USER root
RUN npm install -g \
        typescript \
        ts-node \
        esbuild \
    && npm cache clean --force \
    # Enable corepack so pnpm/yarn are available on demand (pinned per project
    # via packageManager). Its pnpm store defaults to ~/.local/share/pnpm/store,
    # which is the shared host cache bind-mounted by docker-compose.yml.
    && corepack enable

# Drop back to the non-root user for the running container.
USER vscode

# Pre-create the XDG ~/.local tree as vscode. The pnpm-store bind mount
# (~/.local/share/pnpm/store) is several levels deep; if these dirs don't
# already exist in the image, the Docker daemon creates the intermediate
# parents (~/.local, ~/.local/share, ...) as ROOT when attaching the mount.
# That leaves ~/.local unwritable by vscode and breaks tools that write there
# at runtime — e.g. the AWS CloudFormation language server failing with
# "EACCES: permission denied, mkdir '/home/vscode/.local/state/...'".
# Creating them here keeps ownership correct; Docker then mounts onto the leaf.
RUN mkdir -p \
        /home/vscode/.local/share/pnpm/store \
        /home/vscode/.local/state \
        /home/vscode/.local/bin

ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
# Cache locations match the bind mounts in docker-compose.yml (defaults, pinned
# here so they hold even if XDG_* differ).
ENV npm_config_cache=/home/vscode/.npm
