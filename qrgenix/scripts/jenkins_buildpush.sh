# 1. Authenticate with GHCR
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

# 2. Build the image using Compose
docker compose -f docker-compose.ci.yml build

# 2.1 Remove existing container if it exists
docker rm -f qrgenix-ci 2>/dev/null || true

# 3. Run tests inside a fresh container
docker compose -f docker-compose.ci.yml up --abort-on-container-exit
test_status=$?

if [ $test_status -ne 0 ]; then
  # ❌ Tests failed
  curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"❌ *QRgenix Tests Failed*\n*Job:* $JOB_NAME\n*Build:* #$BUILD_NUMBER\n<${BUILD_URL}|View Build>\"
  }" \
  "$SLACK_WEBHOOK"
  exit $test_status
fi

# 4. Tag and push image only if tests passed
docker tag qrgenix-ci ghcr.io/"$GITHUB_USER"/qrgenix:latest
docker push ghcr.io/"$GITHUB_USER"/qrgenix:latest
push_status=$?

if [ $push_status -ne 0 ]; then
  # ❌ Push failed
  curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"⚠️ *QRgenix Push Failed*\n*Job:* $JOB_NAME\n*Build:* #$BUILD_NUMBER\n<${BUILD_URL}|View Build>\"
  }" \
  "$SLACK_WEBHOOK"
  exit $push_status
else
  # ✅ All good
  curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"✅ *QRgenix Build + Push Success*\n*Job:* $JOB_NAME\n*Build:* #$BUILD_NUMBER\n<${BUILD_URL}|View Build>\"
  }" \
  "$SLACK_WEBHOOK"
fi