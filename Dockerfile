# Etap 1 - budowanie zalezności
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Etap 2 - uruchomienie testów
FROM builder AS tester
RUN npm run test

RUN tar -czf /express-app.tar.gz index.js lib/ package.json node_modules/
