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
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    def branch = (env.BRANCH_NAME == 'main') ? 'main' : 'featurebranch'
                    git branch: branch, credentialsId: "${GITHUB_CREDENTIALS_ID}", url: "${GITHUB_REPO}"
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        docker.build("${ECR_REGISTRY}/${REPO_NAME}:stable")
                        docker.build("${ECR_REGISTRY}/${REPO_NAME}:canary")
                    } else {
                        docker.build("${ECR_REGISTRY}/${REPO_NAME}:canary-v2")
                    }
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
                    if (env.BRANCH_NAME == 'main') {
                        docker.withRegistry("https://${ECR_REGISTRY}") {
                            docker.image("${ECR_REGISTRY}/${REPO_NAME}:stable").push()
                            docker.image("${ECR_REGISTRY}/${REPO_NAME}:canary").push()
                        }
                    } else {
                        docker.withRegistry("https://${ECR_REGISTRY}") {
                            docker.image("${ECR_REGISTRY}/${REPO_NAME}:canary-v2").push()
                        }
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
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/deployment-stable.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl apply -f k8s/gateway.yaml
                        kubectl apply -f k8s/destination-rule.yaml
                        kubectl apply -f k8s/virtual-service.yaml
                        '''
                        if (env.BRANCH_NAME != 'main') {
                            input message: 'Approve Canary Deployment?', ok: 'Deploy'
                            sh '''
                            kubectl apply -f k8s/deployment-canary-updated.yaml
                            kubectl apply -f k8s/destination-rule-updated.yaml
                            kubectl apply -f k8s/virtual-service-updated.yaml
                            '''
                        } else {
                            kubectl apply -f k8s/deployment-canary.yaml
                        }
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    sh "docker rmi ${ECR_REGISTRY}/${REPO_NAME}:stable"
                    sh "docker rmi ${ECR_REGISTRY}/${REPO_NAME}:canary"
                    sh "docker rmi ${ECR_REGISTRY}/${REPO_NAME}:canary-v2"
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
