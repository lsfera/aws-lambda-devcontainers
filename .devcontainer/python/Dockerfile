ARG BASE_IMAGE=aws-lambda-base:latest
FROM ${BASE_IMAGE}

USER root

# Python version to install. All active Lambda Python runtimes are supported:
#   3.13  3.12  3.11  (3.10 and 3.9 are deprecated on Lambda)
ARG PYTHON_VERSION=3.13

# Expose the version as a runtime env var so scripts and uv can read it.
ENV PYTHON_VERSION=${PYTHON_VERSION}

# Install Python from deadsnakes PPA (supports all Lambda runtime versions).
# ensurepip bootstraps pip without a separate package dependency.
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       python${PYTHON_VERSION} \
       python${PYTHON_VERSION}-venv \
       python${PYTHON_VERSION}-dev \
    && python${PYTHON_VERSION} -m ensurepip --upgrade \
    && update-alternatives \
         --install /usr/local/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 100 \
    && update-alternatives \
         --install /usr/local/bin/python  python  /usr/bin/python${PYTHON_VERSION} 100 \
    && rm -rf /var/lib/apt/lists/*

USER vscode

# uv (already in the base) handles project-level virtualenvs.
# Tell it which Python to use by default; tool entry points land in ~/.local/bin.
ENV UV_PYTHON=python${PYTHON_VERSION}
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Cache dir matches the shared host bind mount in docker-compose.yml.
ENV UV_CACHE_DIR=/home/vscode/.cache/uv

# Disable pip version nag and Python bytecode noise
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
