#!/bin/bash
set -e

# Resolve absolute script path in case of symlink
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/load-env.sh"

echo "🔍 Checking EC2 instance status for ID: $EC2_INSTANCE_ID..."

aws ec2 describe-instances \
  --instance-ids "$EC2_INSTANCE_ID" \
  --region "$EC2_REGION" \
  --profile "$EC2_PROFILE" \
  --query "Reservations[*].Instances[*].{State:State.Name,IP:PublicIpAddress,Type:InstanceType}" \
  --output table
