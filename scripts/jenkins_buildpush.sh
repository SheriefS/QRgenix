# 1. Authenticate with GHCR
echo "$GHCR_TOKEN" | docker login ghcr.io -u sheriefs --password-stdin

# 2. Build the image using Compose
docker compose -f docker-compose.ci.yml build

# 3. Tag the image for GHCR
docker tag qrgenix-ci ghcr.io/sheriefs/qrgenix:latest

# 4. Push to GHCR
docker push ghcr.io/sheriefs/qrgenix:latest

status=$?

if [ $status -ne 0 ]; then
  curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"❌ *QRgenix Build Failed*\n*Job:* $JOB_NAME\n*Build:* #$BUILD_NUMBER\n*Status:* FAILED\n<${BUILD_URL}|View Build>\"
  }" \
  "$SLACK_WEBHOOK"
  exit $status
else
  curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"✅ *QRgenix Build Success*\n*Job:* $JOB_NAME\n*Build:* #$BUILD_NUMBER\n*Status:* SUCCESS\n<${BUILD_URL}|View Build>\"
  }" \
  "$SLACK_WEBHOOK"
fi