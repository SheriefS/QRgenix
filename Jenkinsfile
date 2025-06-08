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
        script {
          notifySlack("✅", "Stage Completed:* Test Frontend")
        }
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
        script {
          notifySlack("✅", "Stage Completed:* Test Backend")
        }
      }
    }

    stage('Build, Test, and Push Containers (main only)') {
      when {
        branch 'main'
      }
      stages {

        stage('Clean Up Previous Containers') {
          steps {
            sh 'docker rm -f frontend-ci backend-ci || true'
            script {
              notifySlack("🧹", "Stage Completed:* Clean Up Containers")
            }
          }
        }

        stage('Build Containers') {
          steps {
            sh 'docker compose -f docker-compose.ci.yml build'
            script {
              notifySlack("📦", "Stage Completed:* Build Containers")
            }
          }
        }

        stage('Test Backend in Container') {
          steps {
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
              sh 'docker compose -f docker-compose.ci.yml run --rm backend'
            }
            script {
              notifySlack("🧪", "Stage Completed:* Backend Test in Container")
            }
          }
        }

        stage('Test Frontend in Container') {
          steps {
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
              sh 'docker compose -f docker-compose.ci.yml run --rm frontend'
            }
            script {
              notifySlack("🧪", "Stage Completed:* Frontend Test in Container")
            }
          }
        }

        stage('Push Backend Image') {
          steps {
            sh 'echo $GHCR_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin'
            sh 'docker tag qrgenix-backend-ci $GHCR_REGISTRY/$GITHUB_USER/${REPO}-backend:latest'
            sh 'docker push $GHCR_REGISTRY/$GITHUB_USER/${REPO}-backend:latest'
            script {
              notifySlack("🚀", "Stage Completed:* Pushed Backend Image")
            }
          }
        }

        stage('Push Frontend Image') {
          steps {
            sh 'docker tag qrgenix-frontend-ci $GHCR_REGISTRY/$GITHUB_USER/${REPO}-frontend:latest'
            sh 'docker push $GHCR_REGISTRY/$GITHUB_USER/${REPO}-frontend:latest'
            script {
              notifySlack("🚀", "Stage Completed:* Pushed Frontend Image")
            }
          }
        }
      }
    }
  }

  post {
    failure {
      notifySlack("❌", "Failed")
    }
    success {
      notifySlack("✅", "Succeeded")
    }
  }
}

def notifySlack(String emoji, String status) {
  def message = "${emoji} *QRgenix Pipeline ${status}*\n*Job:* ${env.JOB_NAME}\n*Build:* #${env.BUILD_NUMBER}\n<${env.BUILD_URL}|View Build>"
  
  sh """
    curl -X POST -H 'Content-type: application/json' \
    --data '{"text": "${message}"}' "$SLACK_WEBHOOK"
  """
}

