# Step 1: Create virtual environment
python3 -m venv venv
. venv/bin/activate

# Step 2: Upgrade pip
pip install --upgrade pip

# Step 3: Install dependencies
pip install -r requirements.txt

# Step 4: Run tests and create results.xml file
pytest --junitxml=results.xml --maxfail=1 --disable-warnings -q

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