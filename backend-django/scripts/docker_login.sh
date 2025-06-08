#!/bin/bash

# Load environment variables
set -o allexport
source .env
set +o allexport

# Check required vars
if [ -z "$GHCR_PAT" ] || [ -z "$GITHUB_USERNAME" ]; then
  echo "Missing GHCR_PAT or GITHUB_USERNAME in .env"
  exit 1
fi

# Login to GitHub Container Registry
echo "$GHCR_PAT" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin