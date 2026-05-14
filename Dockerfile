# Builder
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Tester
FROM builder AS tester
RUN npm run test

# Runner
FROM node:20-alpine AS runner
WORKDIR /app

# Kopiowanie niezbędnych rzeczy
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/index.js ./
COPY --from=builder /app/lib/ ./lib/

COPY --from=builder /app/examples/ ./examples/

RUN npm install --only=production && npm cache clean --force

# Packager
FROM runner AS packager
RUN apk add --no-cache tar
RUN tar -czf /express-app.tar.gz -C /app .

FROM runner
EXPOSE 3000
CMD ["node", "examples/hello-world/index.js"]
