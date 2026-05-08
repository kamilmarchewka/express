# Etap 1 - budowanie zalezności
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Etap 2 - uruchomienie testów
FROM builder AS tester
CMD ["npm", "run", "test"]
