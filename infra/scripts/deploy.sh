#!/usr/bin/env bash
# Выкат новой версии SL Tracker на сервер.
#
# Запускается на СЕРВЕРЕ, из корня репозитория:
#   ./infra/scripts/deploy.sh
#
# Что делает: забирает свежий код, собирает образы, применяет миграции,
# перезапускает приложение, проверяет, что оно ожило. Данные не трогает.
#
# Первый запуск — по инструкции infra/DEPLOY.md, не этим скриптом.

set -Eeuo pipefail

COMPOSE_FILE="infra/compose/docker-compose.prod.yml"
ENV_FILE=".env"
BRANCH="${DEPLOY_BRANCH:-develop}"

compose() { docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"; }

fail() { echo "ОШИБКА: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

[ -f "$COMPOSE_FILE" ] || fail "запускать из корня репозитория (не вижу $COMPOSE_FILE)"
[ -f "$ENV_FILE" ]     || fail "нет файла .env — см. infra/DEPLOY.md"

step "Забираю код из ветки $BRANCH"
git fetch --prune origin
BEFORE="$(git rev-parse HEAD)"
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
AFTER="$(git rev-parse HEAD)"
if [ "$BEFORE" = "$AFTER" ]; then
  echo "Код не изменился ($(git rev-parse --short HEAD)) — пересоберу и перезапущу всё равно."
else
  echo "Обновлено: $(git rev-parse --short "$BEFORE") -> $(git rev-parse --short "$AFTER")"
  git --no-pager log --oneline "$BEFORE..$AFTER" | head -20
fi

step "Собираю образы"
# Сборка клиента требует около 2 ГБ памяти. Если процесс убивает OOM-killer,
# добавьте своп — как, написано в infra/DEPLOY.md.
compose build

step "Поднимаю базу, Redis и хранилище"
compose up -d postgres redis minio

step "Жду, пока они станут healthy"
for i in $(seq 1 60); do
  UNHEALTHY="$(compose ps --format '{{.Name}} {{.Health}}' | grep -Ev 'healthy$' || true)"
  [ -z "$UNHEALTHY" ] && break
  [ "$i" = "60" ] && fail "не дождался готовности за 5 минут:
$UNHEALTHY"
  sleep 5
done
echo "Готовы."

step "Применяю миграции"
# Одноразовый контейнер. Падает с ненулевым кодом при ошибке — тогда
# set -e останавливает выкат, и приложение не поедет на сломанной базе.
compose --profile tools run --rm migrate

step "Перезапускаю приложение"
compose up -d api caddy
compose ps

step "Проверяю, что API ожил"
for i in $(seq 1 30); do
  if compose exec -T api node -e "fetch('http://127.0.0.1:3000/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" 2>/dev/null; then
    echo "API отвечает."
    break
  fi
  [ "$i" = "30" ] && fail "API не ответил за минуту. Логи: docker compose -f $COMPOSE_FILE logs --tail=100 api"
  sleep 2
done

step "Готово: $(git rev-parse --short HEAD)"
echo "Внешняя проверка: curl -sS https://\${SL_DOMAIN}/api/health"
