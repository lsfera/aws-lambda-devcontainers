FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG NODE_VERSION=lts

# Install build-time dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssh-client \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Pre-populate system-wide SSH known_hosts for common git providers.
# Prevents interactive fingerprint prompts when initialising git submodules.
# Stored in /etc/ssh/ssh_known_hosts so it survives a read-only ~/.ssh mount.
RUN ssh-keyscan -t rsa,ecdsa,ed25519 github.com gitlab.com bitbucket.org 2>/dev/null \
    >> /etc/ssh/ssh_known_hosts

# Install Docker CE CLI + Compose plugin (docker-out-of-docker)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
       https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       docker-ce-cli \
       docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2 (multi-arch)
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/x86_64/;s/arm64/aarch64/') \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" \
       -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# Install Node.js LTS (required for CDK; version lockable via ARG)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CDK — baseline version baked in so CDK is available offline.
# devcontainer-update upgrades to @latest on every container creation.
RUN npm install -g aws-cdk

# Install AWS SAM CLI
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/x86_64/;s/arm64/arm64/') \
    && curl -fsSL "https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-${ARCH}.zip" \
       -o /tmp/sam.zip \
    && unzip -q /tmp/sam.zip -d /tmp/sam-install \
    && /tmp/sam-install/install \
    && rm -rf /tmp/sam.zip /tmp/sam-install

# Install uv — provides uvx, the runtime for all awslabs MCP servers.
# UV_INSTALL_DIR forces a "flat" layout: binaries land directly in this dir
# (no /bin appended), so it must be a directory already on PATH.
RUN curl -fsSL https://astral.sh/uv/install.sh \
    | env UV_INSTALL_DIR=/usr/local/bin UV_UNMANAGED_INSTALL=1 sh \
    && uv --version && uvx --version

# Bake in devcontainer scripts (run at container creation via postCreateCommand)
COPY claude-persist-setup   /usr/local/bin/claude-persist-setup
COPY claude-aws-mcp-setup   /usr/local/bin/claude-aws-mcp-setup
COPY devcontainer-update    /usr/local/bin/devcontainer-update
RUN chmod +x \
    /usr/local/bin/claude-persist-setup \
    /usr/local/bin/claude-aws-mcp-setup \
    /usr/local/bin/devcontainer-update

# Add vscode user (uid 1000) to docker group for socket access
# The GID is overridden at runtime via group_add in docker-compose
RUN groupadd -f docker && usermod -aG docker vscode

USER vscode
# Well-Architected skills and CDK are updated at container creation by devcontainer-update.
