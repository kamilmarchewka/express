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

        stage('Build Artefact .tar.gz') {
            steps {
                sh '''
                    docker create --name extractor express-test-image
                    docker cp extractor:/express-app.tar.gz ./express-app.tar.gz
                    docker rm extractor
                '''
                archiveArtifacts 'express-app.tar.gz'
                sh 'ls'
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
                    echo "--- TREŚĆ ODPOWIEDZI Z SERWERA: ---"
                    curl -v http://localhost:3000 || echo "CURL PADŁ"
                    echo "--- KONIEC ODPOWIEDZI ---"
                '''
            }
        }
    }

    post {
        always {
            echo 'Czyszczenie środowiska...'
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
