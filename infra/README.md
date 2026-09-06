# Инфраструктура SL Tracker

Зона ответственности оркестратора. Прикладной код сюда не кладём.

```
infra/
  compose/   docker-compose для разработки и прода
  caddy/     конфигурация обратного прокси
  scripts/   деплой, бэкапы, утилиты
```

## Быстрый старт локально

```bash
cp .env.example .env      # и заполнить пароли
docker compose -f infra/compose/docker-compose.dev.yml --env-file .env up -d
```

Поднимутся три сервиса данных:

| Сервис | Адрес | Назначение |
|---|---|---|
| PostgreSQL 18.6 | `localhost:5432` | основная база |
| Redis 8.10 | `localhost:6379` | сессии, кэш, очереди BullMQ, pub/sub |
| MinIO | `localhost:9000` (API), `localhost:9001` (консоль) | вложения по S3-протоколу |

Проверить, что всё живо:

```bash
docker compose -f infra/compose/docker-compose.dev.yml --env-file .env ps
```

В колонке `STATUS` у всех трёх должно быть `healthy`, а не просто `running` —
healthcheck'и настоящие, они реально дёргают `pg_isready`, `redis-cli ping`
и `/minio/health/live`.

Остановить, сохранив данные:

```bash
docker compose -f infra/compose/docker-compose.dev.yml --env-file .env down
```

Снести вместе с данными (тома удалятся, база будет пустой):

```bash
docker compose -f infra/compose/docker-compose.dev.yml --env-file .env down -v
```

## Режим «как в проде» (профиль `proxy`)

По умолчанию Flutter и NestJS в разработке живут на разных портах, и cookie-сессия
ведёт себя не так, как в бою. Чтобы этого избежать, поднимается Caddy, собирающий всё
на один origin — `http://localhost:8081` (см.
[ADR-0001](../docs/adr/0001-single-domain-first-party-session.md)).

Сначала запускаются приложения на хосте:

```bash
# NestJS на 3000
cd apps/api && npm run start:dev

# Flutter на 8080
cd apps/web && flutter run -d web-server --web-port 8080
```

Затем прокси:

```bash
docker compose -f infra/compose/docker-compose.dev.yml --env-file .env --profile proxy up -d
```

Приложение открывается на `http://localhost:8081`, API — на `http://localhost:8081/api/*`.
Именно этот адрес прописывается в `YANDEX_REDIRECT_URI` и в Callback URI приложения
на [oauth.yandex.ru](https://oauth.yandex.ru).

## Почему тома смонтированы именно так

В образе `postgres:18-alpine` каталог данных — `/var/lib/postgresql/18/docker`,
а `VOLUME` объявлен на `/var/lib/postgresql`. Это отличается от привычного по PostgreSQL 16
и ниже пути `/var/lib/postgresql/data`.

Если смонтировать старый путь, контейнер запустится и будет работать, но данные окажутся
в анонимном томе и **пропадут при пересоздании контейнера**. Проверено на образе:

```bash
docker run --rm postgres:18-alpine env | grep PGDATA
# PGDATA=/var/lib/postgresql/18/docker
```

## Версии образов

Все теги зафиксированы намеренно — «latest» в инфраструктуре означает, что однажды
утром окружение соберётся другим.

| Образ | Тег | Проверенная версия |
|---|---|---|
| PostgreSQL | `postgres:18-alpine` | 18.6 |
| Redis | `redis:8-alpine` | 8.10.1 |
| MinIO | `quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z` | тот же релиз |
| Caddy | `caddy:2-alpine` | 2.x |

## Чего здесь пока нет

- `docker-compose.prod.yml` — появится, когда будет что деплоить (образы `api` и `web`).
- `scripts/` — деплой и бэкапы базы.
- Настройка бэкапов PostgreSQL и MinIO на VPS.
