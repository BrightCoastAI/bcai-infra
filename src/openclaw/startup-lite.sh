#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg software-properties-common git

# ------------------------------------------------------------------------------
# Node.js 22.x + npm + pnpm
# ------------------------------------------------------------------------------
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Upgrade npm to the latest release
npm install -g npm@latest

# Install pnpm globally
npm install -g pnpm

# ------------------------------------------------------------------------------
# Python (latest) via deadsnakes PPA
# ------------------------------------------------------------------------------
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.12 python3.12-venv python3.12-dev

# Set python3.12 as the default python3
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# ------------------------------------------------------------------------------
# uv (Python package manager)
# ------------------------------------------------------------------------------
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH for all users
if [ -f /root/.local/bin/uv ]; then
  cp /root/.local/bin/uv /usr/local/bin/uv
  cp /root/.local/bin/uvx /usr/local/bin/uvx 2>/dev/null || true
  chmod +x /usr/local/bin/uv /usr/local/bin/uvx 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# OpenClaw
# ------------------------------------------------------------------------------
curl -fsSL https://openclaw.ai/install.sh | bash
