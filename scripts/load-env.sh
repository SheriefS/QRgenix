#!/bin/bash

# Determine project root (adjust if needed)
PROJECT_ROOT="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
ENV_FILE="$PROJECT_ROOT/.env.ec2"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

# Load .env variables (ignore lines that are empty or start with #)
while IFS='=' read -r key value; do
  if [[ -n "$key" && "$key" != \#* ]]; then
    # Remove any surrounding quotes
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    export "$key=$value"
  fi
done < <(grep -Ev '^\s*#|^\s*$' "$ENV_FILE")
