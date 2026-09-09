# Боевой образ клиента: собирает Flutter Web и отдаёт его Caddy.
#
# Лежит в infra, а не в apps/web, намеренно: это артефакт развёртывания,
# а не часть клиентского приложения. Контекст сборки при этом — apps/web
# (см. docker-compose.prod.yml).
#
# Сборка требует ~2 ГБ памяти. На маленьком VPS может понадобиться swap —
# об этом написано в infra/DEPLOY.md.

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Зависимости отдельным слоем: правка кода не тянет за собой повторную загрузку пакетов.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# --wasm даёт Skwasm там, где браузер умеет WasmGC, и автоматический фолбэк
# на JS для остальных (в том числе для всех браузеров на iOS).
RUN flutter build web --wasm --release

FROM caddy:2-alpine AS runtime
# Только собранная статика. Caddyfile монтируется из infra/caddy —
# правка конфигурации не должна требовать пересборки образа.
COPY --from=build /app/build/web /srv/web
