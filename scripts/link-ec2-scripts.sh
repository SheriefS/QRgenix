#!/bin/bash

set -e

# === Config ===
SCRIPT_DIR="$(dirname "$0")"
TARGET_DIR="/usr/local/bin"

echo "🔗 Linking scripts from $SCRIPT_DIR to $TARGET_DIR..."

for script in "$SCRIPT_DIR"/*.sh; do
  script_name=$(basename "$script" .sh)
  link_path="$TARGET_DIR/$script_name"

  if [[ -L "$link_path" || -e "$link_path" ]]; then
    echo "⚠️  $link_path already exists. Skipping."
  else
    echo "➡️  Linking $script -> $link_path"
    sudo ln -s "$script" "$link_path"
  fi
done

echo "✅ All eligible scripts linked!"
