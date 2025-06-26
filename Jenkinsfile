/* groovylint-disable CompileStatic */
pipeline {
  agent any

  environment {
      GHCR_REGISTRY = 'ghcr.io'
      REPO = 'qrgenix'
      SLACK_WEBHOOK = credentials('slack-webhook')
      GITHUB_USER = credentials('github-user')
      GHCR_TOKEN = credentials('ghcr-token')
      PERSIST_DIR = '.jenkins-persist'
      K8S_PENDING_FILE = "${PERSIST_DIR}/k8s-pending.flag"
      BACKEND_PENDING_FILE = "${PERSIST_DIR}/backend-pending.flag"
      FRONTEND_PENDING_FILE = "${PERSIST_DIR}/frontend-pending.flag"
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
            success { script { notifySlackSuccess('✅') } }
            failure { script { notifySlackFailure('❌') } }
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
            success { script { notifySlackSuccess('✅') } }
            failure { script { notifySlackFailure('❌') } }
        }
    }

    stage('Checkout') {
      steps {
        // 🛠️ Ensure Git is present before we diff
        checkout scm
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
                sh "mkdir -p ${PERSIST_DIR}"
                def changedFiles = sh(script: 'git diff --name-only HEAD~1 HEAD', returnStdout: true).trim()

                env.BACKEND_CHANGED = changedFiles.readLines().any { it.startsWith('backend-django/') } ? 'true' : 'false'
                env.FRONTEND_CHANGED = changedFiles.readLines().any { it.startsWith('frontend-vite/') } ? 'true' : 'false'
                env.K8S_CHANGED = changedFiles.readLines().any { it.startsWith('k8s/') } ? 'true' : 'false'
                env.PROJECT_CHANGED = changedFiles.readLines().any {
                  it ==~ /^Jenkinsfile$/ || it.startsWith('docker-compose') || it.startsWith('scripts/') || it.startsWith('Dockerfile')
                } ? 'true' : 'false'

                if (env.BACKEND_CHANGED == 'true') {
                  writeFile file: env.BACKEND_PENDING_FILE, text: 'true'
                }
                if (env.FRONTEND_CHANGED == 'true') {
                  writeFile file: env.FRONTEND_PENDING_FILE, text: 'true'
                }
                if (env.K8S_CHANGED == 'true') {
                  writeFile file: env.K8S_PENDING_FILE, text: 'true'
                }

                echo "Backend Changed: ${env.BACKEND_CHANGED}"
                echo "Frontend Changed: ${env.FRONTEND_CHANGED}"
                echo "K8s Config Changed: ${env.K8S_CHANGED}"
                echo "Project Infra Changed: ${env.PROJECT_CHANGED}"
              }
            }
          }

          stage('Build Frontend Container') {
            when {
              expression { fileExists(env.FRONTEND_PENDING_FILE) || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              sh 'docker compose -f docker-compose.ci.yml build frontend'
            }
            post {
              success { script { notifySlackSuccess('📦') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Build Backend Container') {
            when {
              expression { fileExists(env.BACKEND_PENDING_FILE) || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              sh 'docker compose -f docker-compose.ci.yml build backend'
            }
            post {
              success { script { notifySlackSuccess('📦') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Test Backend in Container') {
            when {
              expression { fileExists(env.BACKEND_PENDING_FILE) || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                sh 'docker compose -f docker-compose.ci.yml run --rm backend'
              }
            }
            post {
              success { script { notifySlackSuccess('🧪') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Test Frontend in Container') {
            when {
              expression { fileExists(env.FRONTEND_PENDING_FILE)  || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                sh 'docker compose -f docker-compose.ci.yml run --rm frontend'
              }
            }
            post {
              success { script { notifySlackSuccess('🧪') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Login to GHCR') {
            when {
              expression { fileExists(env.FRONTEND_PENDING_FILE) || fileExists(env.BACKEND_PENDING_FILE)  || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              withCredentials([
                string(credentialsId: 'ghcr-token', variable: 'GHCR_TOKEN'),
                string(credentialsId: 'github-user', variable: 'GITHUB_USER')
            ])
                {
                sh '''
                        echo $GHCR_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
                    '''
                }
            }
            post {
              success { script { notifySlackSuccess('🔐') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Push Backend Image') {
            when {
              expression { fileExists(env.BACKEND_PENDING_FILE) || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              script {
                def backendImage = "${GHCR_REGISTRY}/${GITHUB_USER}/${REPO}-backend:latest"
                sh "docker tag qrgenix-backend-ci ${backendImage}"
                sh "docker push ${backendImage}"
              }
            }
            post {
              success { script { notifySlackSuccess('🚀') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Push Frontend Image') {
            when {
              expression { fileExists(env.FRONTEND_PENDING_FILE) || env.PROJECT_CHANGED == 'true' }
            }
            steps {
              script {
                def frontendImage = "${GHCR_REGISTRY}/${GITHUB_USER}/${REPO}-frontend:latest"
                sh "docker tag qrgenix-frontend-ci ${frontendImage}"
                sh "docker push ${frontendImage}"
              }
            }
            post {
              success { script { notifySlackSuccess('🚀') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Prepare K8s Manifests') {
            steps {
              sh '''
                echo "🛠️ Preparing NGINX config for Ansible"
                mkdir -p ansible/roles/nginx/files
                cp nginx/nginx.conf ansible/roles/nginx/files/nginx.conf
                echo "🛠️ Preparing K8s manifests for Ansible"
                mkdir -p ansible/roles/k8s/files/staging
                cp k8s/staging/*.yaml ansible/roles/k8s/files/staging/
              '''
            }
            post {
              success { script { notifySlackSuccess('🚀') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Apply Staging K8s YAMLs') {
            when { expression { return fileExists(env.K8S_PENDING_FILE) || env.PROJECT_CHANGED == 'true' } }
            steps {
              sshagent(credentials: ['ec2-ssh-key']) {
                withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'ANSIBLE_VAULT_PASS')]) {
                  sh '''
                    echo "$ANSIBLE_VAULT_PASS" > /tmp/vault-pass.txt
                    chmod 600 /tmp/vault-pass.txt
                    scripts/run_ansible.sh site.yaml
                    scripts/run_ansible.sh apply-manifests.yaml
                    rm -f /tmp/vault-pass.txt
                  '''
                }
              }
            }
            post {
              success {
                script {
                  sh "rm -f ${env.K8S_PENDING_FILE}"
                  notifySlackSuccess('⚙️')
                }
              }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Deploy to K3s') {
            when { expression { fileExists(env.FRONTEND_PENDING_FILE) || fileExists(env.BACKEND_PENDING_FILE) || env.PROJECT_CHANGED == 'true' } }
            steps {
              sshagent(credentials: ['ec2-ssh-key']) {
                withCredentials([string(credentialsId: 'ansible-vault-password', variable: 'ANSIBLE_VAULT_PASS')]) {
                  script {
                    sh 'echo "$ANSIBLE_VAULT_PASS" > /tmp/vault-pass.txt && chmod 600 /tmp/vault-pass.txt'

                    if (fileExists(env.BACKEND_PENDING_FILE)) {
                      sh 'scripts/run_ansible.sh restart-backend.yaml'
                    }
                    if (fileExists(env.FRONTEND_PENDING_FILE)) {
                      sh 'scripts/run_ansible.sh restart-frontend.yaml'
                    }

                    sh 'rm -f /tmp/vault-pass.txt'
                  }
                }
              }
            }
            post {
              success {
                script {
                  sh "rm -f ${env.BACKEND_PENDING_FILE}"
                  sh "rm -f ${env.FRONTEND_PENDING_FILE}"
                  notifySlackSuccess('🚢 Deployed')
                }
              }
              failure { script { notifySlackFailure('❌') } }
            }
          }
        }
      }
  }

  post {
      always {
        script {
          try {
            deleteDir()
          }
          catch (Exception e) {
            echo "⚠️ Could not delete workspace: ${e.getMessage()}"
          }
        }
      }
      failure {
          script {
        notifySlack('❌', 'Pipeline Failed')
          }
      }
      success {
          script {
        notifySlack('✅', 'Pipeline Succeeded')
          }
      }
  }
}

def notifySlack(String emoji, String status) {
  def message = "${emoji} QRgenix Pipeline ${status}\nJob: ${env.JOB_NAME}\nBuild: #${env.BUILD_NUMBER}\n<${env.BUILD_URL}|View Build>"
  sh """
    curl -X POST -H 'Content-type: application/json' --data '{"text": "${message}"}' "$SLACK_WEBHOOK"
    """
}

def notifySlackFailure(String emoji) {
  notifySlack(emoji, "Stage Failed:* ${env.STAGE_NAME}")
}

def notifySlackSuccess(String emoji) {
  notifySlack(emoji, "Stage Succeeded:* ${env.STAGE_NAME}")
}
