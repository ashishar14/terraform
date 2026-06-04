pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        AWS_REGION      = 'ap-south-1'
        TF_VERSION      = '1.9.5'
        TF_WORKING_DIR  = '.'
    }

    stages {

        stage('Git Checkout') {
            steps {
                echo '📥 Checking out code...'
                checkout scm
                sh 'echo "Branch: $(git rev-parse --abbrev-ref HEAD)"'
                sh 'echo "Commit: $(git rev-parse HEAD)"'
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
                    sh '''
                        set -e
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        aws sts get-caller-identity
                        echo "✅ AWS authentication successful"
                    '''
                }
            }
        }

        stage('Terraform Installation') {
            steps {
                echo '⚙️ Checking Terraform installation...'
                sh '''
                    if /usr/local/bin/terraform version 2>/dev/null | grep -q "v${TF_VERSION}"; then
                        echo "✅ Terraform ${TF_VERSION} already installed. Skipping."
                    else
                        echo "🔽 Installing Terraform ${TF_VERSION}..."
                        if command -v apt-get > /dev/null 2>&1; then
                            sudo apt-get update -y
                            sudo apt-get install -y curl unzip
                        elif command -v yum > /dev/null 2>&1; then
                            sudo yum install -y curl unzip
                        fi
                        curl -fsSL \
                            "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" \
                            -o /tmp/terraform.zip
                        sudo unzip -o /tmp/terraform.zip -d /usr/local/bin/
                        sudo chmod +x /usr/local/bin/terraform
                        rm -f /tmp/terraform.zip
                        echo "✅ Terraform installed."
                    fi
                    echo "Version: $(terraform version | head -1)"
                '''
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
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            set -e
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION
                            terraform init -input=false -upgrade
                            echo "✅ Terraform init complete."
                        '''
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
                    dir("${TF_WORKING_DIR}") {
                        sh '''
                            set -e
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION
                            terraform plan -input=false -out=tfplan
                            terraform show -no-color tfplan > plan_output.txt
                            echo "✅ Plan saved to tfplan."
                        '''
                        stash includes: 'tfplan', name: 'tfplan'
                        archiveArtifacts artifacts: 'plan_output.txt', allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                echo '⏸️ Pipeline paused. Waiting for approval...'
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Review the Terraform Plan output. Approve to apply changes to AWS.',
                        ok: 'Approve & Apply'
                    )
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
                    dir("${TF_WORKING_DIR}") {
                        unstash 'tfplan'
                        sh '''
                            set -e
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION
                            terraform apply -input=false -auto-approve tfplan
                            echo "🎉 Terraform apply complete."
                        '''
                    }
                }
            }
        }
    }

    post {
        success { echo '🟢 Pipeline finished successfully.' }
        aborted { echo '🟡 Pipeline aborted — approval declined or timed out.' }
        failure { echo '🔴 Pipeline failed. Check the logs above.' }
        always  { cleanWs() }
    }
}
