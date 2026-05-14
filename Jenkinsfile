pipeline {
    agent any

    environment {
        IMAGE_NAME = "express-prod-app"
        VERSION = "1.0.${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                sh 'docker rm -f hello-world-app extractor || true'
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh 'docker build --target tester -t express-app-test .'
            }
        }

        stage('Build Artefact') {
            steps {
                sh '''
                    mkdir -p artefact artefact/logs
                    ARTEFACT_NAME="express-app-v${VERSION}.tar.gz"

                    echo "Budowanie paczki (Target: packager)..."
                    docker build --target packager -t express-app-pkg .
                    
                    docker rm -f extractor || true
                    docker create --name extractor express-app-pkg
                    docker cp extractor:/express-app.tar.gz ./artefact/${ARTEFACT_NAME}
                    docker rm -f extractor
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Uruchamianie lekkiego obrazu'
                sh '''
                    docker build -t ${IMAGE_NAME}:latest .

                    docker stop hello-world-app || true
                    docker rm hello-world-app || true

                    docker run -d \
                        -p 3000:3000 \
                        --name hello-world-app \
                        ${IMAGE_NAME}:latest
                '''
            }
        }
        
        stage('Smoke Test') {
            steps {
                sh '''
                    sleep 5
                    CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' hello-world-app)
                    echo "Łączę się z IP: $CONTAINER_IP"
                    
                    if curl -s http://$CONTAINER_IP:3000 | grep -q "Hello World"; then
                        echo "Sukces: Aplikacja odpowiada poprawnie"
                        TEST_RESULT=0
                    else
                        echo "Błąd: Brak odpowiedzi Hello World"
                        TEST_RESULT=1
                    fi

                    docker logs hello-world-app > artefact/logs/container_${BUILD_NUMBER}.log 2>&1
                    exit $TEST_RESULT
                '''
            }
        }

        stage('Publish') {
            steps {                
                archiveArtifacts artifacts: 'artefact/**', fingerprint: true
            }
        }
    }

    post {
        always {
            echo 'Sprzątanie'
            sh '''
                docker stop hello-world-app || true
                docker rm -f hello-world-app extractor || true
                docker rmi express-app-test express-app-pkg || true
            '''
        }
        success {
            echo "Pipeline zakończony sukcesem! Artefakt v${VERSION} gotowy."
        }
        failure {
            echo 'Pipeline zakończony niepowodzeniem. Sprawdź logi etapów.'
        }
    }
}
