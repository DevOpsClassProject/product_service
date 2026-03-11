@Library('my-shared-library') _

pipeline {
    agent { node { label 'docker-runner' } }

    environment {
        IMAGE_NAME    = "ecommerce-product"
        REGISTRY_USER = "tejung"
        DOCKER_CREDS  = 'docker-hub-token'

        // Database Secrets (Kept here for deployment context)
        DB_PASSWORD_VAL = credentials('db-password-secret')
    }

    stages {
        // STEP 1: Scan the Source Code (package.json, etc.)
        stage('Security: Source Scan') {
            steps {
                trivyScan(severity: 'HIGH,CRITICAL') 
            }
        }

        // STEP 2 & 3: Build (Internal Tests) + Image Scan + Push
        stage('Build, Test & Delivery') {
            steps {
                dockerBuildPush(
                    registryUser: env.REGISTRY_USER,
                    imageName: env.IMAGE_NAME,
                    credsId: env.DOCKER_CREDS
                )
            }
        }
        stage('Prepare Environment') {
            steps {
                echo 'Cleaning up dangling Docker networks...'
                // -f (force) skips the confirmation prompt
                // || true ensures the pipeline continues even if prune returns a non-zero exit code
                sh 'docker network prune -f || true'
            }
        }
        stage('Deploy') {
            when { 
                anyOf { branch 'develop'; branch 'main'; branch 'release/*' } 
            }
            steps {
                echo "Deploying ${IMAGE_NAME} to ${env.BRANCH_NAME} environment..."
                sh "docker compose up -d ecommerce-product"
            }
        }

    }

    post {
        success {
            echo "Successfully deployed ${IMAGE_NAME} build #${BUILD_NUMBER}"
            build job: '/DevOps project/ecommerce-integration-tests/main', wait: false
        }
        failure {
            echo "Pipeline failed. Check the Jenkins console output for errors."
        }
        always {
            sh 'docker image prune -f'
            deleteDir()
        }
    }
}