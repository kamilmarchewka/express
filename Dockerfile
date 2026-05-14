# --- ETAP 1: Builder ---
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# --- ETAP 2: Tester ---
FROM builder AS tester
RUN npm run test

# --- ETAP 3: Runner (Obraz produkcyjny) ---
FROM node:20-alpine AS runner
WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/index.js ./
COPY --from=builder /app/lib/ ./lib/

RUN npm install --only=production && npm cache clean --force

# --- ETAP 4: Packager (Przygotowanie artefaktu) ---
FROM runner AS packager
RUN apk add --no-cache tar
RUN tar -czf /express-app.tar.gz -C /app .

# Domyślny punkt startowy (używany przez etap Deploy w Jenkins)
FROM runner
EXPOSE 3000
CMD ["node", "index.js"]
