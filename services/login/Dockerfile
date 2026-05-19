# -------- BUILD STAGE --------
FROM node:25-alpine3.22 AS builder

WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy app
COPY . .

# Security: run as non-root
RUN addgroup -S app && adduser -S app -G app
USER app

EXPOSE 3000

CMD ["node", "login.js"]