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

ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
# Cache locations match the bind mounts in docker-compose.yml (defaults, pinned
# here so they hold even if XDG_* differ).
ENV npm_config_cache=/home/vscode/.npm
