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
# `nest build` кладёт в dist и скомпилированный код, и SQL миграций
# (nest-cli.json, раздел assets) — применителю они нужны в рантайме.
RUN npm run build

FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist

USER node
EXPOSE 3000

# Миграции применяются отдельным одноразовым контейнером из этого же образа
# с командой `node dist/database/migrate.js` — до старта API.
# `drizzle-kit` здесь намеренно отсутствует: он dev-зависимость и его конфигурация
# написана на TypeScript, исполнять который в рантайме нечем.
CMD ["node", "dist/main.js"]
