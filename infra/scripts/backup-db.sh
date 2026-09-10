#!/usr/bin/env bash
# Резервная копия базы и вложений SL Tracker.
#
# Запускается на СЕРВЕРЕ из корня репозитория:
#   ./infra/scripts/backup-db.sh
#
# Кладёт архивы в ./backups и удаляет копии старше 14 дней.
# Для ежедневного запуска — в cron:
#   0 4 * * * cd /opt/sl-tracker && ./infra/scripts/backup-db.sh >> backups/backup.log 2>&1
#
# ВАЖНО: копия, лежащая на том же сервере, спасает от испорченных данных,
# но не от потери сервера. Раз в неделю забирайте архив к себе:
#   scp server:/opt/sl-tracker/backups/db-*.sql.gz ./

set -Eeuo pipefail

COMPOSE_FILE="infra/compose/docker-compose.prod.yml"
ENV_FILE=".env"
OUT_DIR="${BACKUP_DIR:-backups}"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
STAMP="$(date +%Y%m%d-%H%M%S)"
# Том MinIO: имя проекта задано в compose-файле (name: sl-tracker).
MINIO_VOLUME="sl-tracker_minio-data"
# Образ для чтения тома: уже есть на сервере (это образ базы), и в нём есть tar и gzip.
TAR_IMAGE="postgres:18-alpine"

compose() { docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"; }
fail() { echo "ОШИБКА: $*" >&2; exit 1; }

[ -f "$COMPOSE_FILE" ] || fail "запускать из корня репозитория"
[ -f "$ENV_FILE" ] || fail "нет файла .env"
# shellcheck disable=SC1090
set -a; . "./$ENV_FILE"; set +a

mkdir -p "$OUT_DIR"
DB_FILE="$OUT_DIR/db-$STAMP.sql.gz"

echo "==> Дамп базы $POSTGRES_DB"
# pg_dump пишет в stdout, сжимаем на лету. Пароль передаётся переменной
# окружения внутрь контейнера и в списке процессов не светится.
compose exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists \
  | gzip -9 > "$DB_FILE"

# Пустой или подозрительно маленький дамп — это провал, а не успех.
SIZE="$(stat -c %s "$DB_FILE")"
[ "$SIZE" -gt 1024 ] || fail "дамп получился $SIZE байт — похоже на ошибку, копия не годится"
echo "Готово: $DB_FILE ($((SIZE / 1024)) КБ)"

echo "==> Проверяю, что архив читается"
gzip -t "$DB_FILE" || fail "архив повреждён"

echo "==> Вложения из MinIO"
FILES_FILE="$OUT_DIR/files-$STAMP.tar.gz"
# В образе MinIO нет ни tar, ни gzip, поэтому том читается одноразовым
# контейнером и только на чтение (:ro) — хранилище при этом не останавливается.
if docker run --rm -v "$MINIO_VOLUME:/data:ro" --entrypoint tar "$TAR_IMAGE" -czf - -C /data . > "$FILES_FILE" \
   && gzip -t "$FILES_FILE"; then
  echo "Готово: $FILES_FILE ($(($(stat -c %s "$FILES_FILE") / 1024)) КБ)"
else
  rm -f "$FILES_FILE"
  echo "ПРЕДУПРЕЖДЕНИЕ: не удалось снять копию вложений. База сохранена."
fi

echo "==> Удаляю копии старше $KEEP_DAYS дней"
find "$OUT_DIR" -name 'db-*.sql.gz' -mtime +"$KEEP_DAYS" -print -delete
find "$OUT_DIR" -name 'files-*.tar.gz' -mtime +"$KEEP_DAYS" -print -delete

echo "==> Что лежит сейчас"
ls -lh "$OUT_DIR" | tail -10
