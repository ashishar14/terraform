pipeline {
    agent { label 'jenkins_node' }

    triggers {
        githubPush()
    }

    environment {
        AWS_REGION          = 'ap-south-1'
        TF_VERSION          = '1.9.5'
        TF_WORKING_DIR      = '.'
        TF_PLUGIN_CACHE_DIR = '/home/ubuntu/.terraform.d/plugin-cache'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/ashishar14/terraform.git'
            }
        }

        stage('AWS Authentication') {
            steps {
                echo '🔐 Authenticating with AWS...'
                withCredentials([[
                    $class:            'AmazonWebServicesCredentialsBinding',
                    credentialsId:     'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh 'set -e && export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID && export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY && export AWS_DEFAULT_REGION=$AWS_REGION && aws sts get-caller-identity && echo done'
                }
            }
        }

        stage('Terraform Installation') {
            steps {
                echo '⚙️ Checking Terraform...'
                sh '/usr/local/bin/terraform version | head -1'
            }
        }

        stage('Terraform Init') {
            options {
                timeout(time: 20, unit: 'MINUTES')
            }
            steps {
                echo '🚀 Initialising Terraform...'
                withCredentials([[
                    $class:            'AmazonWebServicesCredentialsBinding',
                    credentialsId:     'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('.') {
                        sh 'export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID && export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY && export AWS_DEFAULT_REGION=ap-south-1 && export TF_PLUGIN_CACHE_DIR=/var/lib/jenkins/.terraform.d/plugin-cache && mkdir -p /var/lib/jenkins/.terraform.d/plugin-cache && terraform init -input=false -upgrade && echo done'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                echo '📋 Running Terraform plan...'
                withCredentials([[
                    $class:            'AmazonWebServicesCredentialsBinding',
                    credentialsId:     'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('.') {
                        sh 'export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID && export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY && export AWS_DEFAULT_REGION=ap-south-1 && terraform plan -input=false -out=tfplan && terraform show -no-color tfplan > plan_output.txt && echo done'
                        stash includes: 'tfplan', name: 'tfplan'
                        archiveArtifacts artifacts: 'plan_output.txt', allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: 'Approve to apply changes to AWS.', ok: 'Approve & Apply'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                echo '✅ Applying Terraform changes...'
                withCredentials([[
                    $class:            'AmazonWebServicesCredentialsBinding',
                    credentialsId:     'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    dir('.') {
                        unstash 'tfplan'
                        sh 'export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID && export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY && export AWS_DEFAULT_REGION=ap-south-1 && terraform apply -input=false -auto-approve tfplan && echo done'
                    }
                }
            }
        }
    }

    post {
        success { echo '🟢 Pipeline finished successfully.' }
        aborted { echo '🟡 Pipeline aborted.' }
        failure { echo '🔴 Pipeline failed.' }
        always  { cleanWs() }
    }
}
