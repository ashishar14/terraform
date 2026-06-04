pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        AWS_REGION      = 'ap-south-1'        // ← change to your region
        TF_VERSION      = '1.8.5'            // ← change to your Terraform version
        TF_WORKING_DIR  = '.'                // ← path to .tf files (. = repo root)
        TF_VAR_FILE     = 'terraform.tfvars' // ← your var file name
    }

    stages {

        stage('Git Checkout') {
            steps {
                echo '📥 Cloning repository...'
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
                echo '⚙️ Installing Terraform...'
                sh '''
                    if terraform version 2>/dev/null | grep -q "v${TF_VERSION}"; then
                        echo "✅ Terraform ${TF_VERSION} already installed."
                    else
                        echo "Installing Terraform ${TF_VERSION}..."
                        curl -fsSL -o /tmp/terraform.zip \
                            "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
                        unzip -o /tmp/terraform.zip -d /usr/local/bin/
                        chmod +x /usr/local/bin/terraform
                        rm -f /tmp/terraform.zip
                        echo "✅ Terraform $(terraform version | head -1) installed."
                    fi
                '''
            }
        }

        stage('Terraform Init') {
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
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION
                            terraform init -input=false
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
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_DEFAULT_REGION=$AWS_REGION
                            terraform plan \
                                -input=false \
                                -out=tfplan \
                                -var-file="${TF_VAR_FILE}" 2>&1 | tee plan_output.txt
                        '''
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'plan_output.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Manual Approval') {
            steps {
                echo '⏸️ Waiting for manual approval...'
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: 'Review the Terraform Plan. Approve to apply changes to AWS.',
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
                        sh '''
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
        failure { echo '🔴 Pipeline failed. Check the logs.' }
        always  { cleanWs() }
    }
}