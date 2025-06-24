#!/bin/bash
set -e

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/load-env.sh"
source "$SCRIPT_DIR/utils.sh"

# === List Instances ===
mapfile -t INSTANCE_INFO < <(
  aws ec2 describe-instances \
    --region "$EC2_REGION" \
    --profile "$EC2_PROFILE" \
    --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`]|[0].Value, State.Name]' \
    --output text
)

if [[ ${#INSTANCE_INFO[@]} -eq 0 ]]; then
  echo "❌ No EC2 instances found."
  exit 1
fi

echo
echo "Select an EC2 instance to stop:"
for i in "${!INSTANCE_INFO[@]}"; do
  IFS=$'\t' read -r id name state <<< "${INSTANCE_INFO[$i]}"
  echo "$((i+1)). [$state] $name ($id)"
done

read -rp "Enter number (1-${#INSTANCE_INFO[@]}): " selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#INSTANCE_INFO[@]} )); then
  echo "❌ Invalid selection."
  exit 1
fi

IFS=$'\t' read -r EC2_INSTANCE_ID EC2_INSTANCE_NAME EC2_STATE <<< "${INSTANCE_INFO[$((selection-1))]}"

# === Already stopped? ===
if [[ "$EC2_STATE" == "stopped" ]]; then
  echo "🛑 Instance $EC2_INSTANCE_NAME ($EC2_INSTANCE_ID) is already stopped."
  exit 0
fi

# === Stop the instance ===
echo "🛑 Stopping EC2 instance $EC2_INSTANCE_NAME ($EC2_INSTANCE_ID)..."
aws ec2 stop-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE" > /dev/null

echo "⏳ Waiting for instance to stop..."
aws ec2 wait instance-stopped \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE"

echo "✅ Instance $EC2_INSTANCE_NAME has stopped."

# === Clear IP from .env
update_env_var "EC2_PUBLIC_IP" ""
update_env_var "EC2_INSTANCE_ID" "$EC2_INSTANCE_ID"
