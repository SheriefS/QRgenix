pipeline {
  agent any

  environment {
    GHCR_REGISTRY = "ghcr.io"
    REPO = "qrgenix"
    SLACK_WEBHOOK = credentials('slack-webhook')
    GITHUB_USER = credentials('github-user')
    GHCR_TOKEN = credentials('ghcr-token')
  }

  options {
    skipStagesAfterUnstable()
    timestamps()
  }

  stages {

    stage('Check for README-only changes') {
      steps {
        script {
          def changedFiles = sh(script: "git diff-tree --no-commit-id --name-only -r $GIT_COMMIT", returnStdout: true).trim()
          if (changedFiles == 'README.md') {
            echo 'Only README.md changed. Skipping pipeline.'
            currentBuild.result = 'NOT_BUILT'
            error('README-only change')
          }
        }
      }
    }

    stage('Test Frontend (Code Only)') {
      when {
        not { branch 'main' }
      }
      agent {
        docker {
          image 'node:22.16.0'
          args '-u root'
        }
      }
      steps {
        dir('frontend-vite') {
          sh 'npm ci'
          sh 'npm run test'
        }
      }
      post {
        success { script { notifySlackSuccess("✅") } }
        failure { script { notifySlackFailure("❌") } }
      }
    }

    stage('Test Backend (Code Only)') {
      when {
        not { branch 'main' }
      }
      agent {
        docker {
          image 'python:3.12.3'
          args '-u root'
        }
      }
      steps {
        dir('backend-django') {
          sh 'pip install -r requirements.txt'
          sh 'pytest --junitxml=results.xml --maxfail=1 --disable-warnings -q'
        }
      }
      post {
        success { script { notifySlackSuccess("✅") } }
        failure { script { notifySlackFailure("❌") } }
      }
    }

    stage('Build, Test, and Push Containers (main only)') {
      when {
        branch 'main'
      }
      stages {
        stage('Detect Changes') {
          steps {
            script {
              def changedFiles = sh(script: "git diff --name-only HEAD~1 HEAD", returnStdout: true).trim()

              env.BACKEND_CHANGED = changedFiles.contains('backend-django/') ? 'true' : 'false'
              env.FRONTEND_CHANGED = changedFiles.contains('frontend-vite/') ? 'true' : 'false'
              env.K8S_CHANGED = changedFiles.readLines().any { it.startsWith('k8s/') } ? 'true' : 'false'


              echo "Backend Changed: ${env.BACKEND_CHANGED}"
              echo "Frontend Changed: ${env.FRONTEND_CHANGED}"
              echo "K8s Config Changed: ${env.K8s_CHANGED}"
            }
          }
        }

        stage('Clean Up Frontend Container') {
          when {
            expression { env.FRONTEND_CHANGED == 'true' }
          }
          steps {
            sh 'docker rm -f frontend-ci || true'
          }
          post {
            success { script { notifySlackSuccess("🧹") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Clean Up Backend Container') {
          when {
            expression { env.BACKEND_CHANGED == 'true' }
          }
          steps {
            sh 'docker rm -f backend-ci || true'
          }
          post {
            success { script { notifySlackSuccess("🧹") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Build Container Frontend Container') {
          when {
            expression { env.FRONTEND_CHANGED == 'true' }
          } 
          steps {
            sh 'docker compose -f docker-compose.ci.yml build frontend'
          }
          post {
            success { script { notifySlackSuccess("📦") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Build Container Backend Container') {
          when {
            expression { env.BACKEND_CHANGED == 'true' }
          } 
          steps {
            sh 'docker compose -f docker-compose.ci.yml build backend'
          }
          post {
            success { script { notifySlackSuccess("📦") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Test Backend in Container') {
          when {
            expression { env.BACKEND_CHANGED == 'true' }
          }
          steps {
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
              sh 'docker compose -f docker-compose.ci.yml run --rm backend'
            }
          }
          post {
            success { script { notifySlackSuccess("🧪") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Test Frontend in Container') {
          when {
            expression { env.FRONTEND_CHANGED == 'true' }
          }
          steps {
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
              sh 'docker compose -f docker-compose.ci.yml run --rm frontend'
            }
          }
          post {
            success { script { notifySlackSuccess("🧪") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Login to GHCR') {
          when {
            expression { 
              return env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true'
            }
          }
          steps {
            withCredentials([usernamePassword(credentialsId: 'ghcr-token', usernameVariable: 'GH_USER', passwordVariable: 'GH_TOKEN')]) {
              sh '''
                echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
              '''
            }
          }
          post {
            success { script { notifySlackSuccess("🔐") } }
            failure { script { notifySlackFailure("❌ Login to GHCR") } }
          }
        }

        stage('Push Backend Image') {
          when {
            expression { env.BACKEND_CHANGED == 'true' }
          }
          steps {
            script {
              def backendImage = "${GHCR_REGISTRY}/${GITHUB_USER}/${REPO}-backend:latest"
              sh "docker tag qrgenix-backend-ci ${backendImage}"
              sh "docker push ${backendImage}"
            }
          }
          post {
            success { script { notifySlackSuccess("🚀 Backend") } }
            failure { script { notifySlackFailure("❌ Push Backend") } }
          }
        }

        stage('Push Frontend Image') {
          when {
            expression { env.FRONTEND_CHANGED == 'true' }
          }
          steps {
            script {
              def frontendImage = "${GHCR_REGISTRY}/${GITHUB_USER}/${REPO}-frontend:latest"
              sh "docker tag qrgenix-frontend-ci ${frontendImage}"
              sh "docker push ${frontendImage}"
            }
          }
          post {
            success { script { notifySlackSuccess("🚀 Frontend") } }
            failure { script { notifySlackFailure("❌ Push Frontend") } }
          }
        }

        stage('Apply Staging K8s YAMLs') {
          when {
            expression { env.K8S_CHANGED == 'true' }
          }
          steps {
            sshagent(credentials: ['ec2-ssh-key']) {
              withCredentials([usernamePassword(credentialsId: 'github-user', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                sh '''
                  ssh -o StrictHostKeyChecking=no ubuntu@qrgenix.duckdns.org '
                    # Set up kubeconfig if missing
                    [ -f ~/.kube/config ] || (
                      mkdir -p ~/.kube &&
                      sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config &&
                      sudo chown ubuntu:ubuntu ~/.kube/config
                    )

                    # Clone or update repo
                    cd ~/qrgenix || git clone https://github.com/$GIT_USER/qrgenix.git ~/qrgenix
                    cd ~/qrgenix
                    git pull

                    # Apply manifests
                    kubectl apply -f k8s/staging
                  '
                '''
              }
            }
          }
          post {
            success { script { notifySlackSuccess("⚙️") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }

        stage('Deploy to K3s') {
          when {
            expression { env.BACKEND_CHANGED == 'true' || env.FRONTEND_CHANGED == 'true' }
          }
          steps {
            sshagent(credentials: ['ec2-ssh-key']) {
              sh """
                ssh -o StrictHostKeyChecking=no ubuntu@qrgenix.duckdns.org '
                  ${env.BACKEND_CHANGED == 'true' ? "docker pull ghcr.io/$GITHUB_USER/${REPO}-backend:latest && kubectl rollout restart deployment qrgenix-backend -n qrgenix &&" : ""}
                  ${env.FRONTEND_CHANGED == 'true' ? "docker pull ghcr.io/$GITHUB_USER/${REPO}-frontend:latest && kubectl rollout restart deployment qrgenix-frontend -n qrgenix &&" : ""}
                  echo "Deployment Complete"
                '
              """
            }
          }
          post {
            success { script { notifySlackSuccess("🚢") } }
            failure { script { notifySlackFailure("❌") } }
          }
        }
      }
    }
  }

  post {
    failure { notifySlack("❌", "Pipeline Failed") }
    success { notifySlack("✅", "Pipeline Succeeded") }
  }
}

def notifySlack(String emoji, String status) {
  def message = "${emoji} *QRgenix Pipeline ${status}*\n*Job:* ${env.JOB_NAME}\n*Build:* #${env.BUILD_NUMBER}\n<${env.BUILD_URL}|View Build>"
  sh """
    curl -X POST -H 'Content-type: application/json' \
    --data '{"text": "${message}"}' "$SLACK_WEBHOOK"
  """
}

def notifySlackFailure(String emoji) {
  notifySlack(emoji, "Stage Failed:* ${env.STAGE_NAME}")
}

def notifySlackSuccess(String emoji) {
  notifySlack(emoji, "Stage Succeeded:* ${env.STAGE_NAME}")
}
