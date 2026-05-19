# =========================
# 1. Build stage
# =========================
FROM node:22-alpine AS builder

WORKDIR /app

# copy dependency files first (cache optimization)
COPY package.json ./

RUN npm install

# copy source code
COPY . .

#prepare env file

# build production bundle
RUN npm run build


# =========================
# 2. Production stage (nginx)
# =========================
FROM nginx:alpine AS runner

# remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# copy build output
COPY --from=builder /app/build /usr/share/nginx/html

# nginx config for SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]