#!/bin/bash

if [ -f .env ]; then
  source .env
else
  echo "❌ .env file not found. Please create it first."
  exit 1
fi

# === CONFIGURATION ===
JENKINS_URL="https://tplaya.follow-pence.ts.net"  # Replace with your Tailscale domain
JOB_NAME="QRgenix-Test"                   # Replace with your Jenkins job name
TRIGGER_TOKEN="qrgenix-trigger"           # The token you set in Jenkins job
#USERNAME="your_jenkins_username"          # Optional if Jenkins is secured
#API_TOKEN="your_jenkins_api_token"        # Optional if Jenkins is secured

# === BUILD URL ===
TRIGGER_URL="${JENKINS_URL}/job/${JOB_NAME}/build?token=${TRIGGER_TOKEN}"

# === EXECUTE TRIGGER ===
echo "Triggering Jenkins build for job: ${JOB_NAME}"

# If Jenkins is secured:
curl -s -u "${JENKINS_USERNAME}:${JENKINS_API_TOKEN}" -X POST "${TRIGGER_URL}"

# If Jenkins is not secured (or anonymous triggering allowed), comment above and use this:
#curl -s -X POST "${TRIGGER_URL}"

echo "Build trigger sent. Check Jenkins for build status."
