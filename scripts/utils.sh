#!/bin/bash

# Usage: update_env_var KEY VALUE [.env path optional]
# Default .env path is ".env"

update_env_var() {
  local key="$1"
  local value="$2"
  local file="${3:-.env.ec2}"

  if [ ! -f "$file" ]; then
    echo "# Auto-created .env" > "$file"
  fi

  if grep -q "^$key=" "$file"; then
    sed -i "s|^$key=.*|$key=$value|" "$file"
  else
    echo "$key=$value" >> "$file"
  fi
}
