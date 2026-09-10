#!/usr/bin/env bash
# Выкат версии SL Tracker на сервер.
#
# Запускается на СЕРВЕРЕ из корня репозитория:
#   ./infra/scripts/deploy.sh              # свежий develop
#   ./infra/scripts/deploy.sh 1a06d1c      # откат на указанный коммит или тег
#
# Что делает: берёт нужную версию кода, собирает образы, применяет миграции,
# перезапускает приложение и проверяет, что оно ожило. Данные не трогает.
#
# Первое развёртывание идёт не этим скриптом, а по infra/DEPLOY.md.

set -Eeuo pipefail

COMPOSE_FILE="infra/compose/docker-compose.prod.yml"
ENV_FILE=".env"
BRANCH="${DEPLOY_BRANCH:-develop}"
# Первый аргумент — версия для отката. Пусто означает «свежая ветка».
TARGET="${1:-}"

compose() { docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"; }

fail() { echo "ОШИБКА: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

[ -f "$COMPOSE_FILE" ] || fail "запускать из корня репозитория (не вижу $COMPOSE_FILE)"
[ -f "$ENV_FILE" ]     || fail "нет файла .env — см. infra/DEPLOY.md"

BEFORE="$(git rev-parse HEAD)"

if [ -n "$TARGET" ]; then
  step "Откат на $TARGET"
  # Забираем объекты, но НЕ переключаемся на ветку: иначе откат бессмысленен —
  # скрипт вернул бы ту же свежую версию, от которой откатываются.
  git fetch --prune origin
  git checkout --detach "$TARGET" || fail "не нашёл версию $TARGET"
else
  step "Забираю код из ветки $BRANCH"
  git fetch --prune origin
  git checkout "$BRANCH"
  git pull --ff-only origin "$BRANCH"
fi

AFTER="$(git rev-parse HEAD)"
if [ "$BEFORE" = "$AFTER" ]; then
  echo "Версия не изменилась ($(git rev-parse --short HEAD)) — пересоберу и перезапущу всё равно."
else
  echo "Версия: $(git rev-parse --short "$BEFORE") -> $(git rev-parse --short "$AFTER")"
  git --no-pager log --oneline "$BEFORE..$AFTER" 2>/dev/null | head -20 || true
fi

step "Собираю образы"
# Сборка клиента требует около 2 ГБ памяти. Если процесс убит с «Killed» —
# не хватило памяти, добавьте своп (infra/DEPLOY.md, раздел 2).
compose build

step "Поднимаю базу, Redis и хранилище и жду их готовности"
# --wait ждёт именно healthcheck и возвращает ненулевой код, если сервис не ожил.
# Раньше здесь был самодельный цикл по `compose ps`, и он содержал две ошибки:
# проверял все контейнеры (у api и caddy healthcheck нет, они не станут healthy
# никогда) и отсеивал строки по суффиксу «healthy», под который подходит
# и «unhealthy» — упавший сервис считался готовым.
compose up -d --wait postgres redis minio || fail "данные не поднялись, смотри: compose logs postgres redis minio"

step "Применяю миграции"
# Одноразовый контейнер. При ошибке падает с ненулевым кодом, set -e
# останавливает выкат, и приложение не поедет на сломанной базе.
compose run --rm api-migrate || fail "миграции не применились, выкат остановлен"

step "Перезапускаю приложение"
compose up -d api caddy
compose ps

step "Проверяю, что API ожил"
for i in $(seq 1 30); do
  if compose exec -T api node -e "fetch('http://127.0.0.1:3000/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" 2>/dev/null; then
    echo "API отвечает."
    break
  fi
  [ "$i" = "30" ] && fail "API не ответил за минуту. Логи: compose logs --tail=100 api"
  sleep 2
done

step "Готово: $(git rev-parse --short HEAD)"
if [ -n "$TARGET" ]; then
  echo "ВНИМАНИЕ: репозиторий отцеплен от ветки (detached HEAD) — это откат."
  echo "Вернуться на актуальную версию: ./infra/scripts/deploy.sh"
fi
echo "Внешняя проверка: curl -sS https://\$SL_DOMAIN:\$HTTPS_PORT/api/health"
