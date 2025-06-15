#!/bin/bash
set -e


# Resolve absolute script path in case of symlink
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/load-env.sh"
source "$SCRIPT_DIR/utils.sh"

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

if [[ "$INSTANCE_STATE" == "stopped" ]]; then
  echo "🛑 Instance is already stopped."
  exit 0
fi

# === Stop the instance ===
echo "Stopping EC2 instance $EC2_INSTANCE_ID..."
aws ec2 stop-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE" > /dev/null

echo "⏳ Waiting for instance to stop..."
aws ec2 wait instance-stopped \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE"

echo "✅ Instance has stopped."

# Clear the last public IP from .env (optional cleanup)
update_env_var "EC2_PUBLIC_IP" ""
