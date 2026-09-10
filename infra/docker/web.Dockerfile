# Боевой образ клиента: собирает Flutter Web и отдаёт его Caddy.
#
# Лежит в infra, а не в apps/web, намеренно: это артефакт развёртывания,
# а не часть клиентского приложения. Контекст сборки при этом — apps/web
# (см. docker-compose.prod.yml).
#
# Сборка требует ~2 ГБ памяти. На маленьком VPS может понадобиться swap —
# об этом написано в infra/DEPLOY.md.

FROM debian:bookworm-slim AS build

# Flutter ставится из официального архива с точной версией, а не из готового
# образа: сторонний образ ghcr.io/cirruslabs/flutter застрял на 3.44.0 (Dart 3.12),
# а клиенту нужен Dart ^3.13.2 (его требует и freezed 4). Плавающий тег
# вроде «stable» делал сборку невоспроизводимой — версия менялась без нашего ведома.
# Сумма — из https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json
ARG FLUTTER_VERSION=3.47.3
ARG FLUTTER_SHA256=988665565cad9091db1baa54bf6d3868bb40e29719592f3c3a164deefd4208e1

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
 && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/flutter.tar.xz -C /opt --no-same-owner \
 && rm /tmp/flutter.tar.xz \
 && git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:${PATH}"
# Первый запуск разворачивает Dart SDK — отдельным слоем, чтобы не повторять его на каждой сборке.
RUN flutter --version

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
