#!/bin/bash

set -e

# Resolve absolute script path in case of symlink
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/load-env.sh"
source "$SCRIPT_DIR/utils.sh"

# Resolve dynamic path
EC2_KEY_PATH="${EC2_KEY_PATH/\$HOME/$HOME}"

if [[ -z "$EC2_INSTANCE_ID" ]]; then
  echo "❌ EC2_INSTANCE_ID is not set in .env"
  exit 1
fi

# === Check instance state ===
INSTANCE_STATE=$(aws ec2 describe-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text)


if [[ "$INSTANCE_STATE" == "running" ]]; then
  echo "✅ Instance is already running."
else
  # === Start Instance ===
  echo "🚀 Starting EC2 instance $EC2_INSTANCE_ID..."
  aws ec2 start-instances --instance-ids "$EC2_INSTANCE_ID" --region "$EC2_REGION" --profile "$EC2_PROFILE" > /dev/null

  # === Wait for it to be running ===
  echo "⏳ Waiting for instance to enter 'running' state..."
  aws ec2 wait instance-running --instance-ids "$EC2_INSTANCE_ID" --region "$EC2_REGION" --profile "$EC2_PROFILE"
fi

# === Get the Public IP ===
EC2_PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "📡 Instance is running. Public IP: $EC2_PUBLIC_IP"

# Reuse utility function
update_env_var "EC2_PUBLIC_IP" "$EC2_PUBLIC_IP"

# === Optional: SSH in immediately ===
read -p "🔐 Do you want to SSH into the instance now? (y/n): " choice
if [[ $choice == "y" ]]; then
    ssh -i "$KEY_PATH" ubuntu@"$EC2_PUBLIC_IP"
else
  echo "📌 When ready, use:"
  echo "👉 ssh -i \"$EC2_KEY_PATH\" ubuntu@$EC2_PUBLIC_IP"
fi
