pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                echo 'Pobieranie kodu...'
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                sh 'ls -la'
                echo 'Budowanie obrazu (warstwa builder)...'
                sh 'docker build --no-cache --target builder -t express-test-image-builder .'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Uruchamianie testów w kontenerze (Target: tester)...'
                sh 'docker build --no-cache --target tester -t express-test-image-tester .'
            }
        }

        stage('Build App Artefact .tar.gz') {
            steps {
                sh '''
                    mkdir -p artefact/ artefact/logs

                    VERSION="1.0.${BUILD_NUMBER}"
                    ARTEFACT_NAME="express-app-v${VERSION}.tar.gz"

                    docker build --no-cache --target packager -t express-test-image-pkg .
                    
                    docker create --name extractor express-test-image-pkg
                    docker cp extractor:/express-app.tar.gz ./artefact/${ARTEFACT_NAME}
                    docker rm -f extractor
                '''
            }
        }

        stage('Deploy - run hello_world.js') {
            steps {
                echo 'Uruchomienie hello_world.js na localhost:3000'
                sh'''
                    docker stop hello-world-app || true
                    docker rm hello-world-app || true

                    docker build --no-cache -t express-test-image .

                    docker run -d \
                        -p 3000:3000 \
                        --name hello-world-app \
                        express-test-image \
                        node examples/hello-world/index.js
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
                        echo "Sukces: Hello World się wyświetla"
                        TEST_RESULT=0
                    else
                        echo "Błąd: Nie znaleziono frazy"
                        TEST_RESULT=1
                    fi

                    docker logs hello-world-app > artefact/logs/container.log 2>&1 || echo "Kontener nie istniał"
                    
                    exit $TEST_RESULT
                '''
            }
        }

        stage('Publish') {
            steps {                
                sh 'ls'
                sh 'ls artefact/'
                archiveArtifacts artifacts: 'artefact/**', fingerprint: true
            }
        }
    }

    post {
        always {
            echo 'Czyszczenie środowiska...'
            sh 'docker stop hello-world-app'
            sh 'docker rm hello-world-app'
            sh 'docker rmi express-test-image || true'
        }
        success {
            echo 'Pipeline zakończony sukcesem!'
        }
        failure {
            echo 'Coś poszło nie tak. Sprawdź logi.'
        }
    }
}
