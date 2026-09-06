# Сборка API. Многоступенчато: в финальный образ не попадают ни devDependencies,
# ни исходники, ни кэш сборки.
FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:24-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
# Миграции применяются отдельной командой на деплое, поэтому SQL нужен в образе.
COPY --from=build /app/src/database/migrations ./src/database/migrations
COPY --from=build /app/drizzle.config.ts ./drizzle.config.ts

USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
