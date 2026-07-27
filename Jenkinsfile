pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'hadeerelnaghy'
        APP_NAME        = 'devsecops-node-app'
        IMAGE_TAG       = "${BUILD_NUMBER}"

        SONAR_CRED_ID   = 'sonarqube-token'
        SNYK_CRED_ID    = 'snyk-token'
        DOCKER_CRED_ID  = 'dockerhub-credentials'
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['DEV', 'STAGING', 'PROD'],
            description: 'Target environment for deployment'
        )

        string(
            name: 'BRANCH_NAME',
            defaultValue: 'main',
            description: 'Git branch to build and test'
        )

        booleanParam(
            name: 'RUN_SONARQUBE',
            defaultValue: true,
            description: 'Toggle SonarQube SAST scan'
        )

        booleanParam(
            name: 'RUN_SNYK',
            defaultValue: true,
            description: 'Toggle Snyk SCA dependency scan'
        )

        booleanParam(
            name: 'RUN_TRIVY',
            defaultValue: true,
            description: 'Toggle Trivy container image scan'
        )
    }

    stages {

        stage('1. Checkout Source Code') {
            steps {
                echo "Checking out code from branch: ${params.BRANCH_NAME}"

                git(
                    branch: params.BRANCH_NAME,
                    url: 'https://github.com/hadeer-elnaghy/devsecops-node-app.git',
                    credentialsId: 'github-credentials'
                )
            }
        }
        

        // stage('2. SonarQube SAST Analysis') {
        //     when {
        //         expression { return params.RUN_SONARQUBE }
        //     }

        //     steps {
        //         echo 'Executing SonarQube static code analysis via Docker...'

        //         withCredentials([
        //             string(
        //                 credentialsId: env.SONAR_CRED_ID,
        //                 variable: 'SONAR_TOKEN'
        //             )
        //         ]) {
        //             sh '''
        //                 set -e

        //                 echo "Running SonarQube Scanner Container..."

        //                 docker run --rm \
        //                   --network devsecops-net \
        //                   -e SONAR_SCANNER_OPTS="-Xmx1024m -Dsonar.ws.timeout=300" \
        //                   -v "${WORKSPACE}:/usr/src" \
        //                   sonarsource/sonar-scanner-cli:5 \
        //                   -Dsonar.projectKey="${APP_NAME}" \
        //                   -Dsonar.host.url="http://sonarqube:9000" \
        //                   -Dsonar.login="${SONAR_TOKEN}" \
        //                   -Dsonar.ws.timeout=300
        //             '''
        //         }
        //     }
        // }

        // stage('3. Snyk Dependency SCA Scan') {
        //     when {
        //         expression {
        //             return params.RUN_SNYK
        //         }
        //     }

        //     steps {
        //         echo 'Executing Snyk dependency vulnerability scan...'

        //         withCredentials([
        //             string(
        //                 credentialsId: env.SNYK_CRED_ID,
        //                 variable: 'SNYK_TOKEN'
        //             )
        //         ]) {
        //             sh '''
        //                 set -e

        //                 JENKINS_CONTAINER_ID=$(hostname)

        //                 echo "Installing dependencies..."

        //                 docker run --rm \
        //                 --volumes-from "${JENKINS_CONTAINER_ID}" \
        //                 -e SNYK_TOKEN="${SNYK_TOKEN}" \
        //                 -w "${WORKSPACE}" \
        //                 snyk/snyk:node \
        //                 npm install

        //                 echo "Running Snyk vulnerability scan..."

        //                 docker run --rm \
        //                 --volumes-from "${JENKINS_CONTAINER_ID}" \
        //                 -e SNYK_TOKEN="${SNYK_TOKEN}" \
        //                 -w "${WORKSPACE}" \
        //                 snyk/snyk:node \
        //                 snyk test --severity-threshold=high
        //             '''
        //         }
        //     }
        // }

        stage('4. Docker Build Image') {
            steps {
                echo "Building Docker image: ${DOCKER_HUB_USER}/${APP_NAME}:${IMAGE_TAG}"

                sh '''
                    set -e

                    docker build \
                        -t "${DOCKER_HUB_USER}/${APP_NAME}:${IMAGE_TAG}" \
                        -t "${DOCKER_HUB_USER}/${APP_NAME}:latest" \
                        .
                '''
            }
        }

        stage('5. Trivy Image Vulnerability Scan') {
            when {
                expression {
                    return params.RUN_TRIVY
                }
            }

            steps {
                echo 'Executing Trivy vulnerability scan...'

                sh '''
                    set -e

                    IMAGE="${DOCKER_HUB_USER}/${APP_NAME}:${IMAGE_TAG}"

                    echo "Scanning local Docker image: ${IMAGE}"

                    docker image inspect "${IMAGE}" > /dev/null

                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest \
                        image \
                        --image-src docker \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --timeout 10m \
                        "${IMAGE}"
                '''
            }
        }

        stage('6. Push Image to Docker Hub') {
            steps {
                echo 'Pushing verified image to Docker Hub...'

                withCredentials([
                    usernamePassword(
                        credentialsId: env.DOCKER_CRED_ID,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "${DOCKER_PASS}" | docker login \
                            --username "${DOCKER_USER}" \
                            --password-stdin

                        docker push \
                            "${DOCKER_HUB_USER}/${APP_NAME}:${IMAGE_TAG}"

                        docker push \
                            "${DOCKER_HUB_USER}/${APP_NAME}:latest"

                        docker logout
                    '''
                }
            }
        }

        stage('7. Production Manual Approval Gate') {
            when {
                expression {
                    return params.DEPLOY_ENV == 'PROD'
                }
            }

            steps {
                script {
                    echo 'Deployment to PRODUCTION requires manual approval.'

                    input(
                        id: 'PROD_RELEASE_APPROVAL',
                        message: "Approve deployment of release #${env.IMAGE_TAG} to PRODUCTION?",
                        ok: 'Approve & Deploy'
                    )

                    echo 'Production deployment approved.'
                }
            }
        }

        stage('8. Deploy Application') {
            steps {
                script {
                    echo "Deploying application to ${params.DEPLOY_ENV} environment..."

                    if (params.DEPLOY_ENV == 'PROD') {

                        sh '''
                            set -e

                            kubectl set image deployment/${APP_NAME} \
                                node-app=${DOCKER_HUB_USER}/${APP_NAME}:${IMAGE_TAG}

                            kubectl rollout status \
                                deployment/${APP_NAME} \
                                --timeout=180s
                        '''

                    } else {
                        echo "Deploying to non-production environment: ${params.DEPLOY_ENV}"

                        // Add your DEV/STAGING deployment commands here.
                        // Example:
                        // kubectl -n dev set image deployment/${APP_NAME} ...
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace and local build artifacts...'

            sh '''
                docker image prune -f || true
            '''

            cleanWs()
        }

        success {
            echo "SUCCESS: Pipeline executed successfully for ${params.DEPLOY_ENV} environment!"
        }

        failure {
            echo 'FAILURE: Pipeline execution failed. Inspect the logs for security or runtime errors.'
        }
    }
}