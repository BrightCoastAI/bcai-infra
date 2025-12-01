#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "Starting Buildkite agent installation..."

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg dirmngr openssh-client

echo "Adding Buildkite agent repository..."
if ! curl -fsSL "https://keys.openpgp.org/vks/v1/by-fingerprint/32A37959C2FA5C3C99EFBC32A79206696452D198" | gpg --dearmor -o /usr/share/keyrings/buildkite-agent-archive-keyring.gpg; then
  echo "Primary keyserver failed, falling back to keyserver.ubuntu.com"
  curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x32A37959C2FA5C3C99EFBC32A79206696452D198&exact=on&options=mr' | gpg --dearmor -o /usr/share/keyrings/buildkite-agent-archive-keyring.gpg
fi

echo "deb [signed-by=/usr/share/keyrings/buildkite-agent-archive-keyring.gpg] https://apt.buildkite.com/buildkite-agent ${buildkite_agent_release} main" > /etc/apt/sources.list.d/buildkite-agent.list

apt-get update

echo "Installing Buildkite agent..."
apt-get install -y buildkite-agent

echo "Configuring Buildkite agent..."
%{ if buildkite_agent_token_secret != "" ~}
# Fetch token from Secret Manager
echo "Fetching Buildkite agent token from Secret Manager..."
AGENT_TOKEN=$(gcloud secrets versions access latest --secret="${buildkite_agent_token_secret}" --project="${project_id}")
sed -i "s/xxx/$AGENT_TOKEN/g" /etc/buildkite-agent/buildkite-agent.cfg
%{ else ~}
# Use token from variable
sed -i "s/xxx/${buildkite_agent_token}/g" /etc/buildkite-agent/buildkite-agent.cfg
%{ endif ~}
sed -i "s/# queue=.*/queue=\"${buildkite_queue}\"/g" /etc/buildkite-agent/buildkite-agent.cfg
sed -i "s~# endpoint=.*~endpoint=\"${buildkite_api_endpoint}\"~g" /etc/buildkite-agent/buildkite-agent.cfg

%{ if buildkite_agent_tags != "" ~}
sed -i "s/# tags=.*/tags=\"${buildkite_agent_tags}\"/g" /etc/buildkite-agent/buildkite-agent.cfg
%{ endif ~}

echo "Installing Docker engine..."
install -d -m 0755 /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(grep VERSION_CODENAME /etc/os-release | cut -d= -f2) stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker
usermod -a -G docker buildkite-agent

%{ if ssh_key_secret_id != "" ~}
echo "Installing SSH key for repository access..."
install -d -m 0700 -o buildkite-agent -g buildkite-agent /var/lib/buildkite-agent/.ssh
KEY_TMP="$(mktemp)"
KEY_DEST="/var/lib/buildkite-agent/.ssh/id_ed25519"
if gcloud secrets versions access latest --secret="${ssh_key_secret_id}" --project="${project_id}" > "$${KEY_TMP}"; then
  if grep -q "BEGIN OPENSSH PRIVATE KEY" "$${KEY_TMP}"; then
    cat "$${KEY_TMP}" > "$${KEY_DEST}"
  elif base64 -d "$${KEY_TMP}" > "$${KEY_TMP}.decoded" 2>/dev/null && grep -q "BEGIN OPENSSH PRIVATE KEY" "$${KEY_TMP}.decoded"; then
    mv "$${KEY_TMP}.decoded" "$${KEY_DEST}"
  else
    echo "WARN: SSH key from secret ${ssh_key_secret_id} is not a valid OpenSSH private key format."
  fi

  if [ -f "$${KEY_DEST}" ]; then
    chown buildkite-agent:buildkite-agent "$${KEY_DEST}"
    chmod 600 "$${KEY_DEST}"
    if ssh-keygen -lf "$${KEY_DEST}" >/dev/null 2>&1; then
      ssh-keyscan github.com >> /var/lib/buildkite-agent/.ssh/known_hosts
      chown buildkite-agent:buildkite-agent /var/lib/buildkite-agent/.ssh/known_hosts
      chmod 644 /var/lib/buildkite-agent/.ssh/known_hosts
    else
      echo "WARN: SSH key file failed validation; removing it."
      rm -f "$${KEY_DEST}"
    fi
  fi
else
  echo "WARN: Failed to fetch SSH key from Secret Manager (${ssh_key_secret_id}). Continuing without SSH key."
fi
rm -f "$${KEY_TMP}" "$${KEY_TMP}.decoded" || true                           
%{ endif ~}                                                                 

echo "Installing Buildkite Agent Hooks..."

# Create the hooks directory if it doesn't exist
mkdir -p /etc/buildkite-agent/hooks

# Create a global pre-command hook
cat <<'EOF' > /etc/buildkite-agent/hooks/pre-command
#!/bin/bash
set -e

# Ensure uv is installed
if ! command -v uv &> /dev/null; then
  echo "--- :snake: Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Source uv environment
if [ -f "$HOME/.local/bin/env" ]; then
  source "$HOME/.local/bin/env"
elif [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
else
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi

# Ensure bcai-cli is installed
if ! command -v bcai &> /dev/null; then
  echo "--- :inbox_tray: Installing 'bcai' CLI from Main"
  # Use SSH URL since keys are set up
  uv tool install --force "git+ssh://git@github.com/BrightCoastAI/bcai-cli.git@main"
fi

# Verify installation
if ! command -v bcai &> /dev/null; then
    echo "Warning: bcai installed but failed to run"
    exit 1
fi
EOF

# Set permissions for the hook
chown buildkite-agent:buildkite-agent /etc/buildkite-agent/hooks/pre-command
chmod +x /etc/buildkite-agent/hooks/pre-command
                                                                            
echo "Starting Buildkite agent service..."systemctl enable buildkite-agent
systemctl start buildkite-agent

echo "Buildkite agent installation complete!"
