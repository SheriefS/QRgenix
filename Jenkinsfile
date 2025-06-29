/* groovylint-disable CompileStatic, DuplicateStringLiteral, ImplicitClosureParameter, LineLength, MethodParameterTypeRequired, MethodReturnTypeRequired, NestedBlockDepth, NoDef, UnnecessaryObjectReferences, VariableTypeRequired */

pipeline {
  agent any

  /**************** ENV ****************/
  environment {
    GHCR_REGISTRY = 'ghcr.io'
    REPO          = 'qrgenix'
    VERSION       = "${BUILD_NUMBER}"

    SLACK_WEBHOOK = credentials('slack-webhook')
    GITHUB_USER   = credentials('github-user')
    GHCR_TOKEN    = credentials('ghcr-token')
    SSH_KEY_ID    = 'ec2-ssh-key'
    VAULT_PASS_ID = 'ansible-vault-password'
    KCFG_FILE_ID  = 'kubeconfig'
  }

  options {
    timestamps()
    skipStagesAfterUnstable()
    buildDiscarder(logRotator(numToKeepStr:'5', artifactNumToKeepStr:'1'))
  }

  /**************** STAGES **************/
  stages {
    stage('Clean workspace') {
      steps { cleanWs() }
    }

    stage('Checkout') {
      steps { checkout([
        $class: 'GitSCM',
        branches: scm.branches,
        userRemoteConfigs: scm.userRemoteConfigs,
        extensions: [
          [$class: 'CloneOption', shallow: false, depth: 0, noTags: false]
        ]
      ])
      }
    }

    stage('README-only guard') {
      steps {
        script {
          /* Use the env var if it exists, otherwise use the parent commit */
          def base = env.GIT_PREVIOUS_SUCCESSFUL_COMMIT ?: sh(
                      script: 'git rev-parse HEAD~1', returnStdout: true
                    ).trim()

          def changed = sh(
            script: "git diff --name-only ${base} HEAD",
            returnStdout: true
          ).trim()

          if (changed == 'README.md') {
            echo 'Only README.md changed → skipping rest of pipeline.'
            currentBuild.result = 'NOT_BUILT'
            error('README-only change')
          }
        }
      }
      post {
        success {
          script { notifySlackSuccess('ℹ️') }
        }
        failure {
          script { notifySlackFailure('❌') }
        }
      }
    }

    /* -------- Detect changes (sets RUN_FULL) -------- */
    stage('Detect changes') {
      steps {
        script {
          def diff = sh(script:'git diff --name-only origin/main...HEAD', returnStdout:true).trim().readLines()

          env.PIPELINE_CHANGED = diff.any {
            it ==~ /^Jenkinsfile$/ || it.startsWith('scripts/') ||
            it.startsWith('ansible/') || it.startsWith('docker-compose')
          } ? 'true' : 'false'

          env.BACKEND_CHANGED  = diff.any { it.startsWith('backend-django/') } ? 'true' : 'false'
          env.FRONTEND_CHANGED = diff.any { it.startsWith('frontend-vite/') } ? 'true' : 'false'
          env.K8S_CHANGED      = diff.any { it.startsWith('k8s/') } ? 'true' : 'false'

          env.RUN_FULL = (env.BRANCH_NAME == 'main' || env.PIPELINE_CHANGED == 'true') ? 'true' : 'false'
          env.TEST_FULL = (env.BRANCH_NAME != 'main' || env.PIPELINE_CHANGED == 'true') ? 'true' : 'false'

          /* ------------ force everything when pipeline changed ------------ */
          if (env.PIPELINE_CHANGED == 'true') {
            env.BACKEND_CHANGED  = 'true'
            env.FRONTEND_CHANGED = 'true'
            env.K8S_CHANGED      = 'true'
          }

          echo """\
          BACKEND_CHANGED : $BACKEND_CHANGED
          FRONTEND_CHANGED: $FRONTEND_CHANGED
          K8S_CHANGED     : $K8S_CHANGED
          PIPELINE_CHANGED: $PIPELINE_CHANGED
          RUN_FULL        : $RUN_FULL""".stripIndent()
        }
      }
      post {
        success {
          script { notifySlackSuccess('ℹ️') }
        }
        failure {
          script { notifySlackFailure('❌') }
        }
      }
    }

    /* --------------- Feature-branch unit tests --------------- */
    stage('Frontend unit tests') {
      when {
        allOf {
          expression { env.TEST_FULL == 'true' }
          expression { env.FRONTEND_CHANGED == 'true' }
        }
      }
      agent { docker { image 'node:22.16.0'; args '-u root' } }
      steps {
        dir('frontend-vite') { sh 'npm ci && npm run test' }
      }
      post {
        success {
          script { notifySlackSuccess('✅') }
        }
        failure {
          script { notifySlackFailure('❌') }
        }
      }
    }

    stage('Backend unit tests') {
      when {
        allOf {
          expression { env.TEST_FULL == 'true' }
          expression { env.BACKEND_CHANGED == 'true' }
        }
      }
      agent { docker { image 'python:3.12.3'; args '-u root' } }
      steps {
        dir('backend-django') { sh 'pip install -r requirements.txt && pytest -q' }
      }
      post {
        success {
          script { notifySlackSuccess('✅') }
        }
        failure {
          script { notifySlackFailure('❌') }
        }
      }
    }

    /* ======================= FULL BUILD & DEPLOY (RUN_FULL) ======================= */
    stage('Full build/deploy') {
      when { expression { env.RUN_FULL == 'true' } }

      stages {
        stage('Init image tags') {
          steps {
            script {
              env.BACKEND_REPO  = "${GHCR_REGISTRY}/${GITHUB_USER}/${REPO}-backend"
              env.FRONTEND_REPO = "${GHCR_REGISTRY}/${GITHUB_USER}/${REPO}-frontend"
            }
          }
          post { success { script { notifySlackSuccess('ℹ️') } } }
        }

        /* ---------- CI build + tests ---------- */
        stage('Build + test backend CI') {
          when { expression { env.BACKEND_CHANGED == 'true' } }
          steps {
            sh '''
              docker compose -f docker-compose.ci.yml build backend
              docker compose -f docker-compose.ci.yml run --rm backend
            '''
          }
          post {
            success {
              script { notifySlackSuccess('🧪') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        stage('Build + test frontend CI') {
          when { expression { env.FRONTEND_CHANGED == 'true' } }
          steps {
            sh '''
              docker compose -f docker-compose.ci.yml build frontend
              docker compose -f docker-compose.ci.yml run --rm frontend            '''
          }
          post {
            success {
              script { notifySlackSuccess('🧪') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        /* ---------- prod build ---------- */
        stage('Backend prod build') {
          when { expression { env.BACKEND_CHANGED == 'true' } }
          steps { sh 'docker compose -f docker-compose.staging.yaml build backend' }
          post {
            success {
              script { notifySlackSuccess('📦') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        stage('Frontend prod build') {
          when { expression { env.FRONTEND_CHANGED == 'true' } }
          steps { sh 'docker compose -f docker-compose.staging.yaml build frontend' }
          post {
            success {
              script { notifySlackSuccess('📦') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        /* ---------- push ---------- */
        stage('Push images') {
          when { anyOf { expression { env.BACKEND_CHANGED == 'true' } ; expression { env.FRONTEND_CHANGED == 'true' } } }
          steps {
            sh '''
              echo $GHCR_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
              if [ "$BACKEND_CHANGED" = "true" ]; then
                docker tag qrgenix-backend:prod $BACKEND_REPO:$VERSION
                docker tag qrgenix-backend:prod $BACKEND_REPO:latest
                docker push $BACKEND_REPO:$VERSION
                docker push $BACKEND_REPO:latest
              fi
              if [ "$FRONTEND_CHANGED" = "true" ]; then
                docker tag qrgenix-frontend:prod $FRONTEND_REPO:$VERSION
                docker tag qrgenix-frontend:prod $FRONTEND_REPO:latest
                docker push $FRONTEND_REPO:$VERSION
                docker push $FRONTEND_REPO:latest
              fi
            '''
          }
          post {
            success {
              script { notifySlackSuccess('🚀') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        /* ---------- tar & apply manifests ---------- */
        stage('Package manifests') {
          when { expression { env.K8S_CHANGED == 'true' || env.PIPELINE_CHANGED == 'true' } }
          steps { sh 'tar -czf k8s/staging.tar.gz -C k8s/staging .' }
          post {
            success {
              script { notifySlackSuccess('📦') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        stage('Apply manifests') {
          when { expression { env.K8S_CHANGED == 'true' || env.PIPELINE_CHANGED == 'true' } }
          steps {
            withCredentials([
              file(credentialsId: env.KCFG_FILE_ID , variable:'KUBECONFIG_FILE'),
              sshUserPrivateKey(credentialsId: env.SSH_KEY_ID, keyFileVariable:'SSH_KEY'),
              string(credentialsId: env.VAULT_PASS_ID, variable:'VAULT_PASS'),
              string(credentialsId: 'ghcr-token', variable:'GHCR_TOKEN')
            ]) {
              sh '''
                echo "$GHCR_TOKEN" | docker login ghcr.io -u $GITHUB_USER --password-stdin
                scripts/run_ansible.sh apply-manifests.yaml
              '''
            }
          }
          post {
            success {
              script { notifySlackSuccess('⚙️') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }

        /* ---------- rollout ---------- */
        stage('Rollout deployments') {
          when { anyOf { expression { env.BACKEND_CHANGED == 'true' } ; expression { env.FRONTEND_CHANGED == 'true' } } }
          steps {
            withCredentials([
            file(credentialsId: env.KCFG_FILE_ID , variable:'KUBECONFIG_FILE'),
            sshUserPrivateKey(credentialsId: env.SSH_KEY_ID, keyFileVariable:'SSH_KEY'),
            string(credentialsId: env.VAULT_PASS_ID, variable:'VAULT_PASS')
          ]) {
              sh '''
              if [ "$BACKEND_CHANGED" = "true" ];  then scripts/run_ansible.sh restart-backend.yaml;  fi
              if [ "$FRONTEND_CHANGED" = "true" ]; then scripts/run_ansible.sh restart-frontend.yaml; fi
            '''
            }
          }
          post {
            success {
              script { notifySlackSuccess('🚢') }
            }
            failure {
              script { notifySlackFailure('❌') }
            }
          }
        }
      }
    }
  }

  /**************** POST REPORT ****************/
  post {
    always   { deleteDir() }
    failure  {
      script { notifySlack('❌','Pipeline Failed') }
    }
    success  {
      script { notifySlack('✅','Pipeline Succeeded') }
    }
  }
}

/*************** HELPERS (unchanged) ***************/
def notifySlack(String emoji, String status) {
  def msg = "${emoji} QRgenix ${status}\\nJob: ${env.JOB_NAME} #${env.BUILD_NUMBER}\\n<${env.BUILD_URL}|Open>"
  sh "curl -s -X POST -H 'Content-type: application/json' --data '{\"text\":\"${msg}\"}' \"$SLACK_WEBHOOK\""
}

def notifySlackFailure(e) { notifySlack(e, "Stage Failed: ${env.STAGE_NAME}") }
def notifySlackSuccess(e) { notifySlack(e, "Stage Succeeded: ${env.STAGE_NAME}") }
