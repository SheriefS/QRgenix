/* groovylint-disable CompileStatic, DuplicateStringLiteral, LineLength, NoDef, VariableTypeRequired */
// Provisioning job — configures the K3s instance via Ansible.
// Credentials come from AWS Secrets Manager + vault. No Jenkins credentials required.
pipeline {
  agent any

  parameters {
    choice(
      name: 'PLAYBOOK',
      choices: [
        'site.yaml',
        'bootstrap-k3s.yaml',
        'bootstrap-traefik.yaml',
      ],
      description: 'Playbook to run against the K3s instance'
    )
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
  }

  stages {
    stage('Load secrets') {
      steps {
        script {
          env.SLACK_WEBHOOK = sh(script: '''
            docker run --rm --network host amazon/aws-cli \
              secretsmanager get-secret-value \
              --secret-id qrgenix/slack-webhook \
              --query SecretString \
              --output text
          ''', returnStdout: true).trim()
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Provision') {
      steps {
        sh "scripts/run_provision.sh ${params.PLAYBOOK}"
      }
      post {
        success { script { notifySlack('✅', "Provision succeeded: ${params.PLAYBOOK}") } }
        failure { script { notifySlack('❌', "Provision failed: ${params.PLAYBOOK}") } }
      }
    }
  }

  post {
    always { deleteDir() }
  }
}

/***************** HELPERS *****************/
def notifySlack(String emoji, String status) {
  def msg = "${emoji} QRgenix Provisioning — ${status}\\nJob: ${env.JOB_NAME} #${env.BUILD_NUMBER}\\n<${env.BUILD_URL}|Open>"
  sh "curl -s -X POST -H 'Content-type: application/json' --data '{\"text\":\"${msg}\"}' \"${env.SLACK_WEBHOOK}\""
}
