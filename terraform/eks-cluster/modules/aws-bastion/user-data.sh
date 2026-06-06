#!/bin/bash
set -euxo pipefail

############################################
# Error handling
############################################
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

trap 'error_exit "Script failed at line $LINENO. Exit code: $?"' ERR

export DEBIAN_FRONTEND=noninteractive

############################################
# System update & base packages
############################################
apt-get update -y || error_exit "Failed to update package lists"
apt-get upgrade -y || error_exit "Failed to upgrade packages"

apt-get install -y \
  curl \
  git \
  jq \
  ca-certificates \
  gnupg \
  lsb-release \
  bash-completion \
  apt-transport-https \
  unzip || error_exit "Failed to install base packages"

############################################
# AWS CLI v2
############################################
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip \
  || error_exit "Failed to download AWS CLI"

unzip -q /tmp/awscliv2.zip -d /tmp || error_exit "Failed to unzip AWS CLI"

if ! command -v aws &>/dev/null; then
  /tmp/aws/install || error_exit "Failed to install AWS CLI"
fi

rm -rf /tmp/aws /tmp/awscliv2.zip
aws --version || error_exit "AWS CLI verification failed"

############################################
# kubectl
############################################
mkdir -p /etc/apt/keyrings || error_exit "Failed to create keyrings dir"

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key \
  | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
  || error_exit "Failed kubectl key"

chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list \
  || error_exit "Failed kubectl repo"

apt-get update -y || error_exit "kubectl repo update failed"
apt-get install -y kubectl || error_exit "Failed to install kubectl"

############################################
# kubectl completion
############################################
cat <<'EOF' >/etc/profile.d/kubectl.sh
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
EOF

chmod +x /etc/profile.d/kubectl.sh || error_exit "kubectl completion failed"

############################################
# eksctl
############################################
ARCH=amd64
PLATFORM="$(uname -s)_$ARCH"

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" \
  || error_exit "Failed eksctl download"

curl -sL https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt \
  | grep "$PLATFORM" | sha256sum --check - \
  || error_exit "eksctl checksum failed"

tar -xzf "eksctl_$PLATFORM.tar.gz" -C /tmp || error_exit "Failed extract eksctl"
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl || error_exit "Failed install eksctl"

rm -f "eksctl_$PLATFORM.tar.gz" /tmp/eksctl

############################################
# eksctl completion
############################################
cat <<'EOF' >/etc/profile.d/eksctl.sh
source <(eksctl completion bash)
alias e=eksctl
complete -F __start_eksctl e
EOF

chmod +x /etc/profile.d/eksctl.sh || error_exit "eksctl completion failed"

############################################
# Helm
############################################
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
  | gpg --dearmor --yes -o /usr/share/keyrings/helm.gpg \
  || error_exit "Helm key failed"

chmod 644 /usr/share/keyrings/helm.gpg

echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
  | tee /etc/apt/sources.list.d/helm.list \
  || error_exit "Helm repo failed"

apt-get update -y || error_exit "Helm repo update failed"
apt-get install -y helm || error_exit "Helm install failed"

############################################
# Docker
############################################
install -m 0755 -d /etc/apt/keyrings || error_exit "Docker keyring dir failed"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg \
  || error_exit "Docker key failed"

# $(dpkg --print-architecture) and $(lsb_release -cs) are $() subshells
# — Terraform ignores them, bash runs them at runtime. Safe as-is.
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list \
  || error_exit "Docker repo failed"

apt-get update -y || error_exit "Docker update failed"

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  || error_exit "Docker install failed"

systemctl enable docker || error_exit "Docker enable failed"
systemctl start docker || error_exit "Docker start failed"

############################################
# Docker group
############################################
# SUDO_USER and USER are plain $VAR — no braces, Terraform ignores them safely.
# CURRENT_USER="$SUDO_USER" 
# [ -z "$CURRENT_USER" ] && CURRENT_USER="$USER"
CURRENT_USER="ubuntu" 


usermod -aG docker "$CURRENT_USER" || error_exit "Docker group add failed"

############################################
# Workspace
############################################
BASE_DIR="/home/$CURRENT_USER/infra-tools"
ATLANTIS_DIR="$BASE_DIR/atlantis_data"

mkdir -p "$BASE_DIR"     || error_exit "BASE_DIR failed"
mkdir -p "$ATLANTIS_DIR" || error_exit "ATLANTIS_DIR failed"

chown -R "$CURRENT_USER:$CURRENT_USER" "$BASE_DIR"  || error_exit "Ownership failed"
chown -R 100:1000 "$ATLANTIS_DIR"                  || error_exit "Atlantis ownership failed"
chmod 700 "$ATLANTIS_DIR"                           || error_exit "Atlantis chmod failed"

############################################
# Docker compose
# Unquoted <<EOF heredoc so Terraform templatefile values are written
# literally into the file. Bash variables that must survive use $${VAR}.
############################################
cd "$BASE_DIR" || error_exit "cd failed"

cat > docker-compose.yml <<EOF
services:

  vault:
    image: hashicorp/vault:latest
    container_name: vault
    restart: unless-stopped
    ports:
      - "18200:8200"
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: "${vault_root_token}"
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    volumes:
      - vault_data:/vault/data

  atlantis:
    image: ghcr.io/runatlantis/atlantis:latest
    container_name: atlantis
    ports:
      - "4141:4141"
    environment:
      ATLANTIS_ATLANTIS_URL: "http://localhost:4141"
      ATLANTIS_GH_USER: "${git_user}"
      ATLANTIS_GH_TOKEN: "${git_access_token}"
      ATLANTIS_GH_WEBHOOK_SECRET: "${webhook_secret}"
      AWS_ACCESS_KEY_ID: "${aws_access_key_id}"
      AWS_SECRET_ACCESS_KEY: "${aws_secret_access_key}"
      AWS_REGION: "${aws_region}"
    command:
      - server
      - --repo-allowlist=github.com/koyex1/*
    volumes:
      - ./atlantis_data:/home/atlantis/.atlantis

volumes:
  vault_data:
EOF

############################################
# Start containers
############################################
docker compose up -d || error_exit "Docker compose failed"

############################################
# Wait for Atlantis
############################################
for i in $(seq 1 60); do
  if docker ps | grep -q atlantis; then
    echo "Atlantis running"
    break
  fi
  sleep 2
done

############################################
# AWS metadata
############################################
TOKEN=$(curl -s -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") \
  || error_exit "Metadata token failed"

PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4) \
  || error_exit "Public IP fetch failed"

echo "Atlantis: http://$PUBLIC_IP:4141"
echo "Vault:    http://$PUBLIC_IP:18200"

echo "Setup complete"