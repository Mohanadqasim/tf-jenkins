pipeline {
    agent any

    environment {
        AWS_REGION = "eu-central-1"
        ACCOUNT_ID = "272493677884"
        ECR_REPO   = "tf-jenkins-ecr"
        IMAGE_TAG  = "latest"
        APP_HOST   = "3.127.57.236"
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
                ssh -o StrictHostKeyChecking=no ec2-user@$APP_HOST "
                    aws ecr get-login-password --region $AWS_REGION \
                    | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

                    docker pull $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
                    docker stop flask-app || true
                    docker rm flask-app || true

                    docker run -d -p 5000:5000 --name flask-app \
                    $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
                "
                '''
            }
        }

    }
}