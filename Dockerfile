# Etap 1 - budowanie zalezności
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Etap 2: Tester - uruchomienie testów
FROM builder AS tester
RUN npm run test

# Etap 3: Packager - przygotowanie paczki (artefaktu)
FROM tester AS packager
RUN ls -la
RUN tar -czf /express-app.tar.gz index.js lib/ package.json node_modules/
