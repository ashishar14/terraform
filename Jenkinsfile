pipeline {
    agent any
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1' 
        TF_DIR = 'Terraform' 
    }

    stages {
        stage('Git Checkout') {
            steps {
                echo 'Pulling infrastructure configuration blueprints from SCM...'
                git url: 'https://github.com/vikasrawatengg-engg/DevOps.git', branch: 'main'
            }
        }

        stage('Terraform Installation') {
            steps {
                echo 'Verifying and installing Terraform tool binaries...'
                sh '''
                    if ! command -v terraform &> /dev/null; then
                        echo "Terraform missing. Installing packages..."
                        sudo dnf install -y yum-utils
                        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
                        sudo dnf install -y terraform
                    else
                        echo "Terraform is already available:"
                        terraform version
                    fi
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                echo "Initializing backend inside directory: ${TF_DIR}..."
                dir("${TF_DIR}") {
                    // Added credential wrapping here so it can authenticate against your S3 bucket
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                echo 'Generating declarative execution plan matrix...'
                dir("${TF_DIR}") {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Gate: Manual Gate Approval') {
            steps {
                input message: '⚠️ Review the generated Terraform Plan. Do you approve deploying these changes to AWS?', 
                      ok: 'Approve & Apply Changes'
            }
        }

        stage('Terraform Apply') {
            steps {
                echo 'Executing plan target blueprint modifications on AWS infrastructure...'
                dir("${TF_DIR}") {
                    withCredentials([
                        string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh 'terraform apply -input=false tfplan'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up cached plan fragments...'
            dir("${TF_DIR}") {
                sh 'rm -f tfplan'
            }
        }
    }
}
