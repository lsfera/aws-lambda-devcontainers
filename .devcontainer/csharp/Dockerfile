# Extend the Lambda base image.
# Build the base first:
#   docker build -t aws-lambda-base .devcontainer/base
# Or reference it from a registry if you push it there.
ARG BASE_IMAGE=aws-lambda-base:latest
FROM ${BASE_IMAGE}

# Switch to root for system-level installs
USER root

# Install .NET SDK (LTS) from Microsoft package feed
ARG DOTNET_VERSION=9.0
RUN curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb \
       -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common && \
        add-apt-repository ppa:dotnet/backports -y &&\
        apt-get update \
        && apt-get install -y --no-install-recommends \
        dotnet-sdk-${DOTNET_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Switch back to non-root user for user-scoped tooling
USER vscode

# Install AWS Lambda .NET global tools and project templates
RUN dotnet tool install -g Amazon.Lambda.Tools \
    && dotnet new install Amazon.Lambda.Templates

# Persist dotnet tools on PATH for interactive shells
ENV PATH="$PATH:/home/vscode/.dotnet/tools"

# NuGet global-packages dir matches the shared host bind mount in docker-compose.yml.
ENV NUGET_PACKAGES=/home/vscode/.nuget/packages

# Disable .NET telemetry
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1
