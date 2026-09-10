# Развёртывание SL Tracker на своём сервере

Инструкция рассчитана на то, что все команды выполняешь ты сам на сервере.
Каждый шаг заканчивается проверкой — если она не прошла, дальше идти не нужно.

Первое развёртывание — 30–40 минут, половина из них уходит на сборку клиента.

Адреса в тексте — реальные, сервера пользователя (`72.56.41.79`). Проверено: оба
имени резолвятся в этот адрес. При смене сервера заменить их по всему файлу.

---

## 0. Что понадобится

- Сервер с Docker и Docker Compose v2 (`docker compose version` — с пробелом).
- Свободный порт **80** — по нему Let's Encrypt проверяет домен.
- **Минимум 2 ГБ памяти** на время сборки клиента, иначе шаг 2.

## 1. Соседи на сервере

На сервере уже работают Amnezia и агентный харнесс. Обстановка проверена:

| Что | Порт | Мешает нам |
|---|---|---|
| `amnezia-xray` | **TCP 443** | да, поэтому приложение идёт на 8443 |
| `amnezia-awg2` | UDP 32535 | нет |
| `telegram-bot`, `claude-worker` | портов наружу нет | нет |

**TCP 443 занят XRay** — он маскирует VPN под обычный HTTPS. Отбирать у него порт
нельзя: сломается VPN, и, скорее всего, именно обход блокировок. Поэтому трекер
слушает **8443**, а 80-й остаётся Caddy для проверки домена и перенаправления.

HTTP/3 в конфигурации Caddy отключён: он занял бы UDP, где живёт WireGuard.

Если состав сервера изменится, перепроверить так:

```bash
sudo ss -tlnp | grep -E ':(80|8443) '     # должно быть пусто
docker ps --format '{{.Names}}\t{{.Ports}}'
docker network inspect bridge -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
```

Наш стек берёт подсеть `172.28.0.0/16`. Если она занята, поменяй `DOCKER_SUBNET`
в `.env`: пересечение подсетей ничего не роняет сразу, оно молча делает часть
адресов недостижимой, и ищется это тяжело.

## 2. Своп, если памяти меньше 2 ГБ

Сборка Flutter Web съедает около двух гигабайт, и при нехватке система убивает
процесс с невнятным «Killed».

```bash
free -h
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

## 3. Адреса без покупки домена

`sslip.io` — публичный DNS: имя вида `что-угодно.72-56-41-79.sslip.io`
резолвится в `72.56.41.79`. Для Let's Encrypt это обычное доменное имя.

```bash
getent hosts tracker.72-56-41-79.sslip.io
getent hosts s3.72-56-41-79.sslip.io
```

Обе команды должны вывести твой IP.

> Хранилище вынесено на отдельное имя намеренно: подпись S3 считается от хоста
> и пути, и префикс вида `/s3` внутри основного домена ломает проверку подписи
> на стороне MinIO.

## 4. Доступ сервера к репозиторию

```bash
ssh-keygen -t ed25519 -C "sl-tracker deploy" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
```

Строку добавь в GitHub: репозиторий → **Settings → Deploy keys → Add deploy key**.
Галочку «Allow write access» **не ставь**.

```bash
ssh -T git@github.com
sudo mkdir -p /opt && sudo chown "$USER" /opt
git clone git@github.com:Vladislav-Zyuzko/sl-tracker.git /opt/sl-tracker
cd /opt/sl-tracker && git checkout develop
```

## 5. Приложение в Яндекс ID

В [oauth.yandex.ru](https://oauth.yandex.ru) добавь **второй** Redirect URI
(локальный не удаляй, он нужен для разработки):

```
https://tracker.72-56-41-79.sslip.io:8443/api/auth/yandex/callback
```

Порт в адресе — часть адреса, и совпадать он должен символ в символ.
Права прежние: `login:info`, `login:email`, `login:avatar`.

> Если форма откажется принимать адрес с портом — напиши мне, план Б есть.

## 6. Файл `.env`

```bash
cd /opt/sl-tracker && cp .env.example .env
for n in POSTGRES_PASSWORD REDIS_PASSWORD MINIO_ROOT_PASSWORD SESSION_SECRET; do
  echo "$n=$(openssl rand -base64 32 | tr -d '/+=')"
done
```

Заполни `.env` (`nano .env`):

```ini
POSTGRES_PASSWORD=<из вывода>
REDIS_PASSWORD=<из вывода>
MINIO_ROOT_PASSWORD=<из вывода>
SESSION_SECRET=<из вывода>

HTTP_PORT=80
HTTPS_PORT=8443

SL_DOMAIN=tracker.72-56-41-79.sslip.io
SL_S3_DOMAIN=s3.72-56-41-79.sslip.io
SL_ACME_EMAIL=твоя@почта

APP_BASE_URL=https://tracker.72-56-41-79.sslip.io:8443
MINIO_PUBLIC_URL=https://s3.72-56-41-79.sslip.io:8443
YANDEX_REDIRECT_URI=https://tracker.72-56-41-79.sslip.io:8443/api/auth/yandex/callback

YANDEX_CLIENT_ID=<из кабинета Яндекса>
YANDEX_CLIENT_SECRET=<из кабинета Яндекса>

# Кого пускать в трекер. Без этого не войдёт никто, включая тебя.
# Адреса — те, что Яндекс возвращает в профиле.
ACCESS_LIST_BOOTSTRAP_EMAILS=твой@адрес,коллега@адрес,ещё-коллега@адрес
```

```bash
grep -c 'change-me' .env      # должно быть 0
git check-ignore -v .env      # должен показать правило игнорирования
chmod 600 .env
```

> `APP_BASE_URL` обязан начинаться с `https://` — из протокола выводится флаг
> `Secure` у cookie сессии. По `http://` кука уйдёт без него, и перехвативший
> трафик получит чужую сессию. Порт в адресе указывать обязательно.

## 7. Запуск

```bash
cd /opt/sl-tracker
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env build
```

Сборка клиента — 5–15 минут: внутри образа скачивается Flutter SDK
и компилируется приложение. Дальше слои кэшируются.

```bash
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env up -d
```

Порядок соблюдается сам: сначала база, Redis и хранилище дожидаются состояния
healthy, затем одноразовый контейнер применяет миграции, и только если он
завершился успешно — стартуют API и прокси. Упавшие миграции останавливают
запуск, а не пропускают приложение на сломанную схему.

```bash
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env ps
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env logs api-migrate
```

В логе миграций должно быть видно поимённо, что применилось.

## 8. Проверка

```bash
curl -sS https://tracker.72-56-41-79.sslip.io:8443/api/health
```

Ожидаемо: `{"status":"ok","postgres":{"status":"up"...`.

Если сертификата нет — смотри логи Caddy:

```bash
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env logs --tail=50 caddy
```

Частые причины: закрыт 80-й порт извне (проверь фаервол хостинга, не только
`ufw`), имя не резолвится, исчерпан лимит Let's Encrypt после неудачных попыток.

Дальше открой `https://tracker.72-56-41-79.sslip.io:8443` и войди через Яндекс ID.
Отказ во входе означает, что твоего адреса нет в `ACCESS_LIST_BOOTSTRAP_EMAILS` —
проверка идёт до создания сессии, это защита, а не поломка.

## 9. Ежедневные копии

```bash
./infra/scripts/backup-db.sh      # первый прогон вручную
crontab -e
```

```
0 4 * * * cd /opt/sl-tracker && ./infra/scripts/backup-db.sh >> backups/backup.log 2>&1
```

> Копия на том же сервере спасает от испорченных данных, но не от потери сервера.
> Раз в неделю забирай архив к себе:
> `scp server:/opt/sl-tracker/backups/db-*.sql.gz ./`

---

## Обновление версии

```bash
cd /opt/sl-tracker && ./infra/scripts/deploy.sh
```

Скрипт забирает код, собирает образы, применяет миграции, перезапускает
приложение и проверяет, что оно ожило. При ошибке останавливается.

## Если что-то пошло не так

```bash
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env logs --tail=100 api

# Откат на предыдущую версию
git log --oneline -10
./infra/scripts/deploy.sh <хеш>

# Остановка (данные остаются)
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env down
```

**Никогда не запускай `down -v`** на боевом сервере: `-v` удаляет тома, то есть
базу, вложения и сертификаты.

## Как убрать порт из адреса

Порт `:8443` в ссылках — плата за соседство с XRay на 443. Убрать его можно:

1. **Купить домен и второй IP** — самый чистый путь: XRay остаётся на своём
   адресе, трекер получает свой и слушает обычный 443.
2. **Настроить XRay на отдачу трекера как «сайта-прикрытия»** — штатный режим
   XRay: он терминирует TLS на 443 и передаёт непрофильный трафик дальше.
   Работает, но это правка конфигурации работающего VPN, и делать её надо
   осознанно.
3. **Перевести VPN на другой порт** — сработает, но 443 у XRay выбран не
   случайно: именно он делает трафик неотличимым от обычного HTTPS.

## Переезд на собственный домен

1. A-записи `tracker.` и `s3.` на IP сервера.
2. В `.env` поменять пять значений: `SL_DOMAIN`, `SL_S3_DOMAIN`, `APP_BASE_URL`,
   `MINIO_PUBLIC_URL`, `YANDEX_REDIRECT_URI`.
3. Добавить новый Redirect URI в кабинете Яндекса.
4. `./infra/scripts/deploy.sh`

Caddy выпустит сертификаты сам. Старые ссылки на задачи перестанут открываться —
это неизбежная цена смены адреса.
