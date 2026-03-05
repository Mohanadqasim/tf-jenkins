pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/Mohanadqasim/tf-jenkins'
            }
        }

        stage('Test') {
            steps {
                sh 'ls -la'
            }
        }
    }
}