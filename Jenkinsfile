pipeline {
    agent any

    environment {
        REPO_NAME = 'demo'
        GITHUB_REPO = 'https://github.com/Sureshreddyc/ct-k8s-canary-deployment.git'
        GITHUB_CREDENTIALS_ID = 'GITHUB_PAT'
        AWS_CREDENTIALS_ID = 'aws-credentials'
        ECR_REGISTRY = '630777559208.dkr.ecr.ap-south-1.amazonaws.com'
        ECR_REGION = 'ap-south-1'
        KUBECONFIG_PATH = "${WORKSPACE}/kubeconfig"
        NAMESPACE = 'canary'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: "${GITHUB_CREDENTIALS_ID}", url: "${GITHUB_REPO}"
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    docker.build("${ECR_REGISTRY}/${REPO_NAME}:stable")
                    docker.build("${ECR_REGISTRY}/${REPO_NAME}:canary")
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                        sh "aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    }
                }
            }
        }

        stage('Push Docker Images to ECR') {
            steps {
                script {
                    sh 'echo "Pushing Docker images to ECR"'
                    docker.withRegistry("https://${ECR_REGISTRY}") {
                        docker.image("${ECR_REGISTRY}/${REPO_NAME}:stable").push()
                        docker.image("${ECR_REGISTRY}/${REPO_NAME}:canary").push()
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG'), [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                        sh '''
                        export KUBECONFIG=${KUBECONFIG_PATH}
                        aws eks --region ${ECR_REGION} update-kubeconfig --name my-new-cluster --kubeconfig $KUBECONFIG
                        kubectl apply -f namespace.yaml
                        kubectl apply -f deployment-stable.yaml
                        kubectl apply -f deployment-canary.yaml
                        kubectl apply -f service.yaml
                        kubectl apply -f gateway.yaml
                        kubectl apply -f destination-rule.yaml
                        kubectl apply -f virtual-service.yaml
                        '''
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    sh "docker rmi ${ECR_REGISTRY}/${REPO_NAME}:stable"
                    sh "docker rmi ${ECR_REGISTRY}/${REPO_NAME}:canary"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
