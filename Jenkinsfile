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
    }

    stage('Build, Test, and Push Containers (main only)') {
      when {
        branch 'main'
      }
      stages {

        stage('Clean Up Previous Containers') {
          steps {
            sh 'docker rm -f frontend-ci backend-ci || true'
          }
        }

        stage('Build Containers') {
          steps {
            sh 'docker compose -f docker-compose.ci.yml build'
          }
        }

        stage('Test Backend in Container') {
          steps {
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
              sh 'docker compose -f docker-compose.ci.yml run --rm backend'
            }
          }
        }

        stage('Test Frontend in Container') {
          steps {
            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
              sh 'docker compose -f docker-compose.ci.yml run --rm frontend'
            }
          }
        }

        stage('Push Backend Image') {
          steps {
            sh 'echo $GHCR_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin'
            sh 'docker tag qrgenix-backend-ci $GHCR_REGISTRY/$GITHUB_USER/${REPO}-backend:latest'
            sh 'docker push $GHCR_REGISTRY/$GITHUB_USER/${REPO}-backend:latest'
          }
        }

        stage('Push Frontend Image') {
          steps {
            sh 'docker tag qrgenix-frontend-ci $GHCR_REGISTRY/$GITHUB_USER/${REPO}-frontend:latest'
            sh 'docker push $GHCR_REGISTRY/$GITHUB_USER/${REPO}-frontend:latest'
          }
        }
      }
    }
  }

  post {
    failure {
      script {
        def msg = """❌ *QRgenix Pipeline Failed*\n*Job:* ${env.JOB_NAME}\n*Build:* <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"""
        sh """
          curl -X POST -H 'Content-type: application/json' \
          --data '{"text": "${msg.replaceAll('"', '\\"')}"}' \
          "$SLACK_WEBHOOK"
        """
      }
    }
    success {
      script {
        def msg = """✅ *QRgenix Pipeline Succeeded*\n*Job:* ${env.JOB_NAME}\n*Build:* <${env.BUILD_URL}|#${env.BUILD_NUMBER}>"""
        sh """
          curl -X POST -H 'Content-type: application/json' \
          --data '{"text": "${msg.replaceAll('"', '\\"')}"}' \
          "$SLACK_WEBHOOK"
        """
      }
    }
  }
}
