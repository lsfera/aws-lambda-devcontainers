# AWS Lambda Devcontainers

Devcontainer configurations for AWS Lambda development. All variants share a common base image that packages the AWS toolchain, Docker-out-of-Docker support, and Claude Code with pre-configured AWS MCP servers. Claude Code configuration and memory persist across container rebuilds via a bind mount to the host.

## Variants

| Variant | Adds to base |
|---------|-------------|
| **base** | — |
| **csharp** | .NET SDK 9, `Amazon.Lambda.Tools`, Lambda project templates |
| **python** | Python 3.13 (deadsnakes PPA), Ruff, `uv` project management |
| **typescript** | TypeScript compiler, ts-node, esbuild, ESLint + Prettier |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2 on Linux)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

## First-time setup

```bash
.devcontainer/build.sh
```

This builds the base image, generates `.devcontainer/.env` with your host's paths, and creates the persistence directories. Run it once — or again whenever `Dockerfile` changes.

Then open the repository in VS Code, run **Dev Containers: Reopen in Container**, and pick a variant. On first creation `devcontainer-update` runs automatically and prints a version summary.

## Using this config with a separate workspace

This `.devcontainer/` is reusable infrastructure — your **project repos stay clean and contain no devcontainer files**. You bring a config and a workspace together at launch with the `devcontainer` CLI:

```bash
devcontainer up \
  --workspace-folder ./my-workspace \
  --config .devcontainer/typescript/devcontainer.json \
  --remove-existing-container
```

`initializeCommand` walks up from the workspace folder to find this `.devcontainer/init.sh`, then mounts the **workspace folder** (not the config's repo root) at `/workspaces/<workspace-basename>`, and sets it as the container's working directory. `devcontainer-update` then initialises that project's own git submodules.

### Opening it in VS Code

Use the **`open.sh`** helper — it brings the container up and opens VS Code **directly at the mounted workspace**, in one step:

```bash
.devcontainer/open.sh ./my-workspace typescript
#                      <workspace>      <variant, default: base>
```

This works because VS Code's GUI devcontainer flows ("Reopen in Container", "Open Folder in Container") all expect a `.devcontainer` *inside* the opened folder — which your workspace deliberately doesn't have. `open.sh` sidesteps that: it runs `devcontainer up`, then opens VS Code with the attached-container remote URI pointed straight at `/workspaces/<project>`.

> **Why not plain "Attach to Running Container"?** That command always opens `/home/vscode` and ignores the devcontainer's `workspaceFolder`/`working_dir`. After attaching you'd have to **File → Open Folder → `/workspaces/<project>`** manually (VS Code then remembers it for that container). `open.sh` just does this for you up front.
>
> For shell-only work: `devcontainer exec --workspace-folder ./my-workspace --config .devcontainer/typescript/devcontainer.json bash` (lands in the workspace via `working_dir`).

> The workspace path is written to `.env` on every launch, so switching between projects just works. Avoid launching two projects against the same shared config simultaneously — they share one `.env`.

## Updating

`devcontainer-update` runs on every container creation. Run it at any time inside the container to pull fresh sources without a full rebuild:

```bash
devcontainer-update
```

| Source | How it updates | Requires |
|--------|---------------|---------|
| AWS CDK | `npm install -g aws-cdk@latest` | `devcontainer-update` |
| Well-Architected skills | re-runs bootstrap from GitHub | `devcontainer-update` |
| AWS MCP servers | re-registered via `claude mcp add` at `@latest` | `devcontainer-update` |
| AWS CLI, SAM CLI | new installer download | `build.sh` (image rebuild) |
| Node.js, Python, .NET | new apt/PPA package | `build.sh` (image rebuild) |
| Docker CLI, uv | new release | `build.sh` (image rebuild) |

---

## What every container includes

### AWS toolchain

| Tool | Notes |
|------|-------|
| AWS CLI v2 | Multi-arch (x86_64 / aarch64) |
| AWS CDK | Global npm install |
| AWS SAM CLI | Local Lambda emulation and event generation |
| Node.js LTS | Required by CDK; available for JS/TS handlers |
| Docker CE CLI + Compose plugin | Docker-out-of-Docker — no daemon, no `--privileged` |
| uv + uvx | Python package runner; drives all AWS MCP servers |

### Claude Code

Installed via `ghcr.io/anthropics/devcontainer-features/claude-code:1`. On first container creation, four AWS MCP servers are registered at user scope and written to the persisted config:

| Server | What it does |
|--------|-------------|
| `aws-docs` | Search AWS API references, guides, What's New |
| `aws-iac` | CDK constructs, CloudFormation schema, security validation |
| `aws-lambda` | Invoke deployed Lambda functions as Claude tools |
| `aws-serverless` | SAM CLI build/deploy/invoke, local test events |

MCP servers are fetched on demand via `uvx` — no pre-install, always the latest version. AWS credentials are resolved at runtime from the standard credential chain (`~/.aws/credentials`, environment variables, or IAM role).

```bash
claude mcp list   # verify after container starts
```

### Well-Architected skills

The [AWS Well-Architected Skills & Steering](https://github.com/aws-samples/sample-well-architected-skills-and-steering) bootstrap runs on every container creation via `devcontainer-update`. This installs Claude Code slash commands and a Well-Architected `CLAUDE.md` into `~/.claude/commands/`.

| Command | What it does |
|---------|-------------|
| `/wa-review` | Review current code against the AWS Well-Architected Framework |
| `/security-assessment` | Security-focused assessment of the current codebase |

Because `claude-persist-setup` runs first, commands are written into the shared persist directory and survive subsequent rebuilds.

### Security model

The container process runs as `vscode` (uid 1000) — never root. The host Docker socket is bind-mounted for Docker-out-of-Docker; `--privileged` is not used.

AWS credentials are **never baked into any image**. `~/.aws` is bind-mounted from the host at runtime (see [AWS credentials](#aws-credentials) below).

---

## Variant details

### base

The foundation image and the default config (`.devcontainer/devcontainer.json`, auto-detected by VS Code). Use it directly for language-agnostic CDK and SAM work — it already includes Node.js + CDK, so TypeScript/CDK projects work here too — or as the `FROM` target when building new variants.

**VS Code extensions:** AWS Toolkit, Docker

### csharp

Adds the .NET SDK and Lambda-specific tooling on top of base.

| Tool | Notes |
|------|-------|
| .NET SDK 9 | Version controlled via `DOTNET_VERSION` in `.env` |
| `Amazon.Lambda.Tools` | `dotnet lambda deploy-function`, `dotnet lambda package`, etc. |
| `Amazon.Lambda.Templates` | `dotnet new lambda.EmptyFunction`, `lambda.SQS`, etc. |

**VS Code extensions:** AWS Toolkit, Docker, C#, C# Dev Kit, .NET Runtime

### python

Adds Python and project tooling on top of base.

| Tool | Notes |
|------|-------|
| Python (deadsnakes PPA) | Version controlled via `PYTHON_VERSION` in `.env`; supports all active Lambda runtimes (3.11, 3.12, 3.13) |
| uv | Manages per-project virtualenvs (`uv venv`, `uv run`, `uv add`); interpreter pinned to the installed Python |
| Ruff | Linter and formatter; auto-applied on save |

Project dependencies (`boto3`, `aws-lambda-powertools`, etc.) belong in `pyproject.toml` — the container provides the runtime and toolchain, not the libraries.

**VS Code extensions:** AWS Toolkit, Docker, Python, Pylance, debugpy, Ruff

### typescript

Node.js LTS already ships in the base image (CDK depends on it). This variant adds the authoring toolchain on top.

| Tool | Notes |
|------|-------|
| TypeScript (`tsc`) | Installed globally |
| ts-node | Run `.ts` directly for handler experiments and scripts |
| esbuild | Fast bundler used by CDK `NodejsFunction` and SAM esbuild builds |

Project dependencies (`aws-sdk`, `@types/aws-lambda`, `aws-lambda-powertools`, etc.) belong in the project's `package.json` — the container provides the toolchain, not the libraries. `editor.formatOnSave` uses Prettier with ESLint auto-fix.

**VS Code extensions:** AWS Toolkit, Docker, ESLint, Prettier

---

## Git submodules

All variants support workspaces that use git submodules, including private ones.

**How it works:**

1. `~/.ssh` is bind-mounted read-only into every container (`SSH_DIR` in `.env`)
2. Fingerprints for `github.com`, `gitlab.com`, and `bitbucket.org` are baked into the image at `/etc/ssh/ssh_known_hosts`, so the read-only SSH mount doesn't block on fingerprint prompts
3. `devcontainer-update` detects `.gitmodules` at the workspace root and runs `git submodule update --init --recursive` automatically

Because the SSH mount is read-only, `known_hosts` updates (new hosts or rotated keys) won't persist inside the container. For hosts not pre-populated in the image, set `StrictHostKeyChecking=accept-new` in your host `~/.ssh/config`:

```
# ~/.ssh/config  (host-side)
Host my-internal-git.example.com
    StrictHostKeyChecking accept-new
```

**Private submodule layout example:**

```
workspace-root/
├── .devcontainer/      ← points to this setup
├── .gitmodules
├── services/
│   ├── user-service/   ← private git submodule (C# Lambda)
│   └── data-pipeline/  ← private git submodule (Python Lambda)
└── infrastructure/     ← CDK stacks (in main repo)
```

`devcontainer-update` will show how many submodules were initialised in its output. Run it again at any time to pull the latest submodule commits:

```bash
devcontainer-update
```

**Note on pre-populated known_hosts:** GitHub, GitLab, and Bitbucket rotate their SSH host keys occasionally. If submodule clones fail with a host-key error, rebuild the image (`build.sh`) to re-run `ssh-keyscan` and pick up the new fingerprints.

## AWS credentials

`~/.aws` from your host is bind-mounted read-write into every container at `/home/vscode/.aws`. All variants share the same credentials directory, and nothing is ever copied into an image.

The path defaults to `$HOME/.aws` and is written to `.env` by `init.sh`. Override it if your credentials live elsewhere:

```bash
# .devcontainer/.env
AWS_CONFIG_DIR=/path/to/your/.aws
```

Because the mount is read-write, credential workflows that modify local files work normally:

```bash
aws configure                         # write static credentials
aws sso login --profile my-profile    # refresh SSO token
aws configure set region eu-west-1    # update config
```

If `~/.aws` doesn't exist on your host yet, Docker creates it automatically on container start (via `create_host_path: true`). Run `aws configure` inside the container to populate it.

## Claude Code persistence

Config, MCP registrations, memory, and project history survive container rebuilds via a bind mount.

```
~/.devcontainer-claude/          ← on your host, never touched by Docker
├── claude.json                  ← MCP registrations, user settings
└── data/
    ├── settings.json
    ├── projects/                ← per-project memory and conversation history
    └── todos/
```

Inside the container, `~/.claude.json` and `~/.claude/` are symlinks into this directory. `claude-persist-setup` (baked into the base image) creates the symlinks as the first step of `postCreateCommand` — before MCP registration runs — so everything written by Claude Code lands in the persisted location.

---

## Shared dependency caches

Each language's package cache/store is bind-mounted from a host directory (default under `$HOME/.devcontainer-cache/`) to the tool's default location in-container. Downloads are therefore **shared across every project and container**, and survive rebuilds — the first `pnpm install` / `uv sync` / `dotnet restore` in any project warms the cache for all the others.

| Variant | Host dir (default) | Container mount | Tool |
|---------|-------------------|-----------------|------|
| base, typescript | `~/.devcontainer-cache/npm` | `~/.npm` | npm cache |
| typescript | `~/.devcontainer-cache/pnpm` | `~/.local/share/pnpm/store` | pnpm store (corepack-provided) |
| python | `~/.devcontainer-cache/uv` | `~/.cache/uv` | uv cache |
| csharp | `~/.devcontainer-cache/nuget` | `~/.nuget/packages` | NuGet global packages |

`init.sh` creates these host directories before the mounts are attached, and the paths are overridable in `.env`.

> On macOS/VirtioFS, `node_modules`/`.venv`/`bin`+`obj` themselves stay on the workspace bind mount (fast enough, and project-local). Only the **shared** download caches move to a host path — these are content-addressable (pnpm/NuGet) or pure download caches (npm/uv), so sharing them is safe. pnpm can't hard-link from the store into a `node_modules` on a different mount, so it copies — you still avoid re-downloads, just not on-disk dedup.

---

## Configuration

`.devcontainer/.env` is generated by `init.sh` / `build.sh` and gitignored. Edit it to change any default, then run **Dev Containers: Rebuild Container**.

```bash
# Absolute host path to SSH keys (default: $HOME/.ssh)
# Bind-mounted read-only; used for private git submodule access
SSH_DIR=/your/custom/.ssh

# Absolute host path to AWS credentials (default: $HOME/.aws)
AWS_CONFIG_DIR=/your/custom/.aws

# Absolute host path for Claude Code persistence (default: $HOME/.devcontainer-claude)
CLAUDE_PERSIST_HOST_DIR=/your/custom/path

# Docker socket (default: /var/run/docker.sock)
# Rootless Docker on Linux: /run/user/<UID>/docker.sock
DOCKER_SOCK=/var/run/docker.sock

# GID of the docker group on the host
# Linux: stat -c '%g' /var/run/docker.sock
# macOS: stat -f '%g' /var/run/docker.sock
DOCKER_GID=docker

# Base image tag
BASE_IMAGE=aws-lambda-base:latest

# C# variant — .NET SDK major version
DOTNET_VERSION=9.0

# Python variant — must match an active Lambda runtime (3.11, 3.12, 3.13)
PYTHON_VERSION=3.13

# Shared dependency caches (host paths, default under $HOME/.devcontainer-cache)
NPM_CACHE_HOST_DIR=/your/custom/npm
PNPM_STORE_HOST_DIR=/your/custom/pnpm
UV_CACHE_HOST_DIR=/your/custom/uv
NUGET_HOST_DIR=/your/custom/nuget
```

---

## File structure

The **base** config lives at the `.devcontainer/` root — this is what VS Code
auto-detects and offers as the default "Reopen in Container". Language variants
are subfolders that extend the base image and remain selectable via the
"Dev Containers: Reopen in Container" picker.

```
.devcontainer/
├── devcontainer.json            # BASE — VS Code's auto-detected default config
├── Dockerfile                   # Base image: AWS CLI, CDK, SAM, Docker CLI, Node, uv
├── docker-compose.yml           # Base compose (mounts, DooD, persistence)
├── claude-persist-setup         # CONTAINER: symlinks ~/.claude* → bind mount
├── claude-aws-mcp-setup         # CONTAINER: registers AWS MCP servers
├── devcontainer-update          # CONTAINER: updates CDK, WA skills, MCP servers
│
├── init.sh                      # HOST: generates .env, pre-creates Claude persist dir
├── build.sh                     # HOST: builds the base image
├── open.sh                      # HOST: up + open VS Code at a separate workspace
├── .env                         # generated, gitignored
├── .env.example                 # committed template
├── .gitignore
│
├── csharp/
│   ├── Dockerfile               # FROM aws-lambda-base + .NET SDK + Lambda tools
│   ├── devcontainer.json
│   └── docker-compose.yml
│
├── python/
│   ├── Dockerfile               # FROM aws-lambda-base + Python (deadsnakes PPA)
│   ├── devcontainer.json
│   └── docker-compose.yml
│
└── typescript/
    ├── Dockerfile               # FROM aws-lambda-base + tsc, ts-node, esbuild
    ├── devcontainer.json
    └── docker-compose.yml
```

---

## Adding a new language variant

1. **Dockerfile** — extend the base image:

   ```dockerfile
   ARG BASE_IMAGE=aws-lambda-base:latest
   FROM ${BASE_IMAGE}

   USER root
   # install language runtime and system packages

   USER vscode
   # install user-scoped tools (language package managers, global CLIs, etc.)
   ```

2. **`docker-compose.yml`** — copy from an existing variant (e.g. `typescript/docker-compose.yml`). Add a `build.args` entry for any new build argument. Keep all volume mounts (workspace, SSH, AWS, Claude persist, Docker socket) unchanged.

3. **`devcontainer.json`** — copy from an existing variant; only `name` and the `extensions`/`settings` differ. The shared plumbing must stay identical:

   ```jsonc
   {
     "name": "AWS Lambda <Lang>",
     "dockerComposeFile": "docker-compose.yml",
     "service": "devcontainer",
     "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
     // walks up from the workspace to find .devcontainer/init.sh (supports nested workspaces)
     "initializeCommand": "bash -c 'ws=\"$1\"; d=\"$ws\"; while [ \"$d\" != \"/\" ]; do if [ -f \"$d/.devcontainer/init.sh\" ]; then exec bash \"$d/.devcontainer/init.sh\" \"$ws\"; fi; d=$(dirname \"$d\"); done; exit 1' -- ${localWorkspaceFolder}",
     "features": { "ghcr.io/anthropics/devcontainer-features/claude-code:1": {} },
     "remoteUser": "vscode",
     "postCreateCommand": "claude-persist-setup && devcontainer-update"
   }
   ```

4. **`init.sh`** — add the new variant to the symlink loop so `.env` is available to Docker Compose (base is omitted — it reads the root `.env` directly):

   ```bash
   for subdir in csharp python typescript <lang>; do
   ```

5. Run `build.sh` if you changed `Dockerfile`; otherwise just open the new variant in VS Code.
