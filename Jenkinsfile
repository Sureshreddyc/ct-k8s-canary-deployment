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
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: "*/${env.BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        credentialsId: "${GITHUB_CREDENTIALS_ID}", 
                        url: "${GITHUB_REPO}"
                    ]]
                ])
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    def imageTag = env.BRANCH_NAME == 'main' ? 'stable' : 'canary'
                    docker.build("${ECR_REGISTRY}/${REPO_NAME}:${imageTag}")
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh "aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Push Docker Images to ECR') {
            steps {
                script {
                    def imageTag = env.BRANCH_NAME == 'main' ? 'stable' : 'canary'
                    docker.withRegistry("https://${ECR_REGISTRY}") {
                        docker.image("${ECR_REGISTRY}/${REPO_NAME}:${imageTag}").push()
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([
                    file(credentialsId: 'kubeconfig-credentials-id', variable: 'KUBECONFIG'), 
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]
                ]) {
                    sh '''
                    export KUBECONFIG=${KUBECONFIG_PATH}
                    aws eks --region ${ECR_REGION} update-kubeconfig --name my-new-cluster --kubeconfig $KUBECONFIG
                    '''
                    script {
                        if (env.BRANCH_NAME == 'main') {
                            sh '''
                            kubectl apply -f k8s-new/namespace.yaml
                            kubectl apply -f k8s-new/myapp-stable-deployment.yaml -n canary
                            '''
                        } else {
                            sh '''
                            kubectl apply -f k8s-new/myapp-canary-deployment.yaml -n canary
                            kubectl apply -f k8s-new/myapp-virtualservice.yaml -n canary
                            kubectl apply -f k8s-new/myapp-destinationrule.yaml -n canary
                            kubectl apply -f k8s-new/gateway.yaml -n canary
                            '''
                        }
                    }
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
