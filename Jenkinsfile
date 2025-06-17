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

                env.BACKEND_CHANGED = changedFiles.contains('backend-django/') ? 'true' : 'false'
                env.FRONTEND_CHANGED = changedFiles.contains('frontend-vite/') ? 'true' : 'false'
                env.K8S_CHANGED = changedFiles.readLines().any { it.startsWith('k8s/') } ? 'true' : 'false'

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
              }
            }
          }

          stage('Clean Up Frontend Container') {
            when {
              expression { fileExists(env.FRONTEND_PENDING_FILE) }
            }
            steps {
              sh 'docker rm -f frontend-ci || true'
            }
            post {
              success { script { notifySlackSuccess('🧹') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Clean Up Backend Container') {
            when {
              expression { fileExists(env.BACKEND_PENDING_FILE) }
            }
            steps {
              sh 'docker rm -f backend-ci || true'
            }
            post {
              success { script { notifySlackSuccess('🧹') } }
              failure { script { notifySlackFailure('❌') } }
            }
          }

          stage('Build Frontend Container') {
            when {
              expression { fileExists(env.FRONTEND_PENDING_FILE) }
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
              expression { fileExists(env.BACKEND_PENDING_FILE) }
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
              expression { fileExists(env.BACKEND_PENDING_FILE) }
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
              expression { fileExists(env.FRONTEND_PENDING_FILE) }
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
              expression { fileExists(env.FRONTEND_PENDING_FILE) || fileExists(env.BACKEND_PENDING_FILE) }
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
            expression { fileExists(env.BACKEND_PENDING_FILE) }
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
            expression { fileExists(env.FRONTEND_PENDING_FILE) }
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

        stage('Apply Staging K8s YAMLs') {
          when { expression { return fileExists(env.K8S_PENDING_FILE) } }
          steps {
            sshagent(credentials: ['ec2-ssh-key']) {
              sh 'ansible-playbook -i inventory/hosts.ini apply-manifests.yaml'
            }
          }
        }

        stage('Deploy to K3s') {
          when { expression { fileExists(env.FRONTEND_PENDING_FILE) || fileExists(env.BACKEND_PENDING_FILE) } }
          steps {
            sshagent(credentials: ['ec2-ssh-key']) {
              script {
                if (fileExists(env.BACKEND_PENDING_FILE)) {
                  sh 'ansible-playbook -i inventory/hosts.ini restart-backend.yaml'
                }
                if (fileExists(env.FRONTEND_PENDING_FILE)) {
                  sh 'ansible-playbook -i inventory/hosts.ini restart-frontend.yaml'
                }
              }
            }
          }
        }

        // stage('Apply Staging K8s YAMLs') {
        //   when {
        //     expression {
        //       return fileExists(env.K8S_PENDING_FILE)
        //     }
        //   }
        //   steps {
        //     sshagent(credentials: ['ec2-ssh-key']) {
        //       withCredentials([
        //           string(credentialsId: 'github-user', variable: 'GIT_USER'),
        //           string(credentialsId: 'ghcr-token', variable: 'GIT_TOKEN')
        //       ]) {
        //         sh '''
        //       ssh -o StrictHostKeyChecking=no ubuntu@qrgenix.duckdns.org '
        //         [ -f ~/.kube/config ] || (
        //           mkdir -p ~/.kube &&
        //           sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config &&
        //           sudo chown ubuntu:ubuntu ~/.kube/config
        //         )

        //         cd ~/qrgenix || git clone https://github.com/$GIT_USER/qrgenix.git ~/qrgenix
        //         cd ~/qrgenix
        //         git pull

        //         kubectl apply -f k8s/staging
        //       '
        //     '''
        //       }
        //     }
        //   }
        //   post {
        //     success {
        //       script {
        //         sh "rm -f ${env.K8S_PENDING_FILE}"
        //         notifySlackSuccess('⚙️')
        //       }
        //     }
        //     failure { script { notifySlackFailure('❌') } }
        //   }
        // }

        // stage('Deploy to K3s') {
        //   when {
        //     expression { fileExists(env.FRONTEND_PENDING_FILE) || fileExists(env.BACKEND_PENDING_FILE) }
        //   }
        //   steps {
        //     script {
        //       def backendCmd = fileExists(env.BACKEND_PENDING_FILE) ? "kubectl rollout restart deployment qrgenix-backend -n qrgenix && rm -f ${env.BACKEND_PENDING_FILE} &&" : ''
        //       def frontendCmd = fileExists(env.FRONTEND_PENDING_FILE) ? "kubectl rollout restart deployment qrgenix-frontend -n qrgenix && rm -f ${env.FRONTEND_PENDING_FILE} &&" : ''

        //       sshagent(credentials: ['ec2-ssh-key']) {
        //         sh """
        //           ssh -o StrictHostKeyChecking=no ubuntu@qrgenix.duckdns.org '
        //             ${backendCmd}
        //             ${frontendCmd}
        //             echo "Deployment Complete"
        //           '
        //         """
        //       }
        //     }
        //   }
        //   post {
        //     success { script { notifySlackSuccess('🚢 Deployed') } }
        //     failure { script { notifySlackFailure('❌ Deployment') } }
        //   }
        // }
      }
    }
  }

  post {
      failure { notifySlack('❌', 'Pipeline Failed') }
      success { notifySlack('✅', 'Pipeline Succeeded') }
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
