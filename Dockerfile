# AI Accept 2026-04-10 master v1
# Uptime Kuma - Jenkins Docker 部署专用 Dockerfile
# 两阶段构建：builder 构建前端，release 只保留运行时依赖

FROM node:20-bookworm-slim AS builder

WORKDIR /app

COPY .npmrc .npmrc
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production

COPY .npmrc .npmrc
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=builder /app/server ./server
COPY --from=builder /app/db ./db
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/extra ./extra
COPY --from=builder /app/config ./config
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/server.js ./server.js

EXPOSE 3001

CMD ["node", "server/server.js"]
