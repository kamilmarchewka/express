pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Pobieranie kodu...'
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                echo 'Budowanie obrazu dockerowego...'
                sh 'docker build -t express-test-image .'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Uruchamianie testów w kontenerze...'
                sh 'docker run --rm express-test-image'
            }
        }

        stage('Build App Artefact .tar.gz') {
            steps {
                sh '''
                    mkdir -p artefact/ artefact/logs
                    docker create --name extractor express-test-image
                    docker cp extractor:/express-app.tar.gz ./artefact/express-app.tar.gz
                    docker rm extractor
                '''
            }
        }

        stage('Deploy - run hello_world.js') {
            steps {
                echo 'Uruchomienie hello_world.js na localhost:3000'
                sh'''
                    docker stop hello-world-app || true
                    docker rm hello-world-app || true

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
            sh 'docker rmi express-test-image || true'
            sh 'docker stop hello-world-app'
            sh 'docker rm hello-world-app'
        }
        success {
            echo 'Pipeline zakończony sukcesem!'
        }
        failure {
            echo 'Coś poszło nie tak. Sprawdź logi.'
        }
    }
}
