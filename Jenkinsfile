pipeline {
    agent any

    environment {
        AWS_REGION = "eu-central-1"
        ACCOUNT_ID = "272493677884"
        ECR_REPO   = "tf-jenkins-ecr"
        IMAGE_TAG  = "latest"
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $ECR_REPO .'
            }
        }

        stage('Tag Image') {
            steps {
                sh 'docker tag $ECR_REPO:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG'
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION \
                | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                '''
            }
        }

        stage('Push Image') {
            steps {
                sh 'docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG'
            }
        }

        stage('Deploy to App EC2') {
            steps {
                sh '''
                ssh -o StrictHostKeyChecking=no ec2-user@3.127.57.236 << EOF

                aws ecr get-login-password --region eu-central-1 \
                | docker login --username AWS --password-stdin 272493677884.dkr.ecr.eu-central-1.amazonaws.com

                docker pull 272493677884.dkr.ecr.eu-central-1.amazonaws.com/tf-jenkins-ecr:latest

                docker stop flask-app || true
                docker rm flask-app || true

                docker run -d -p 5000:5000 --name flask-app \
                272493677884.dkr.ecr.eu-central-1.amazonaws.com/tf-jenkins-ecr:latest

                EOF
                '''
            }
        }

    }
}