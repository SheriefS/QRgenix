#!/bin/bash

set -e

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/load-env.sh"
source "$SCRIPT_DIR/utils.sh"

EC2_KEY_PATH="${EC2_KEY_PATH/\$HOME/$HOME}"

# === List EC2 instances ===
echo "📦 Fetching EC2 instances in region $EC2_REGION..."

mapfile -t INSTANCE_INFO < <(
  aws ec2 describe-instances \
    --region "$EC2_REGION" \
    --profile "$EC2_PROFILE" \
    --query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`]|[0].Value, State.Name]' \
    --output text
)

if [[ ${#INSTANCE_INFO[@]} -eq 0 ]]; then
  echo "❌ No EC2 instances found in region $EC2_REGION."
  exit 1
fi

# === Display list ===
echo
echo "Select an EC2 instance to start:"
for i in "${!INSTANCE_INFO[@]}"; do
  IFS=$'\t' read -r id name state <<< "${INSTANCE_INFO[$i]}"
  echo "$((i+1)). [$state] $name ($id)"
done

# === User selection ===
echo
read -rp "Enter number (1-${#INSTANCE_INFO[@]}): " selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#INSTANCE_INFO[@]} )); then
  echo "❌ Invalid selection."
  exit 1
fi

IFS=$'\t' read -r EC2_INSTANCE_ID EC2_INSTANCE_NAME EC2_STATE <<< "${INSTANCE_INFO[$((selection-1))]}"
echo "📌 Selected: $EC2_INSTANCE_NAME ($EC2_INSTANCE_ID) [$EC2_STATE]"

# === Start if not running ===
if [[ "$EC2_STATE" == "running" ]]; then
  echo "✅ Instance is already running."
else
  echo "🚀 Starting EC2 instance $EC2_INSTANCE_ID..."
  aws ec2 start-instances --instance-ids "$EC2_INSTANCE_ID" --region "$EC2_REGION" --profile "$EC2_PROFILE" > /dev/null
  echo "⏳ Waiting for instance to enter 'running' state..."
  aws ec2 wait instance-running --instance-ids "$EC2_INSTANCE_ID" --region "$EC2_REGION" --profile "$EC2_PROFILE"
fi

# === Get Public IP ===
EC2_PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "📡 Instance is running. Public IP: $EC2_PUBLIC_IP"

# === Store result if desired ===
update_env_var "EC2_PUBLIC_IP" "$EC2_PUBLIC_IP"
update_env_var "EC2_INSTANCE_ID" "$EC2_INSTANCE_ID"

# === SSH? ===
read -p "🔐 Do you want to SSH into the instance now? (y/n): " choice
if [[ $choice == "y" ]]; then
    ssh -i "$EC2_KEY_PATH" ubuntu@"$EC2_PUBLIC_IP"
else
  echo "📌 When ready, use:"
  echo "👉 ssh -i \"$EC2_KEY_PATH\" ubuntu@$EC2_PUBLIC_IP"
fi
