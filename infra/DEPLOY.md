# Развёртывание SL Tracker на своём сервере

Инструкция рассчитана на то, что все команды выполняешь ты сам на сервере.
Каждый шаг заканчивается проверкой — если она не прошла, дальше идти не нужно.

Ориентировочное время первого развёртывания: 30–40 минут, из них половина —
ожидание сборки клиента.

---

## 0. Что понадобится

- Сервер с Docker и Docker Compose v2.
- Открытые порты **80 и 443** (Let's Encrypt проверяет домен по 80-му, без него сертификата не будет).
- **Минимум 2 ГБ оперативной памяти** на время сборки клиента. Если меньше — сначала шаг 1.
- IP-адрес сервера. Дальше в тексте он обозначен как `185.12.34.56` — подставляй свой.

Проверь версии:

```bash
docker --version
docker compose version   # нужна v2: команда с пробелом, а не docker-compose
```

## 0.1. Соседи на сервере: проверка конфликтов

На сервере уже работают VPN (Amnezia) и агентный харнесс в Docker. Сначала
убедимся, что мы никого не потесним.

```bash
sudo ss -tulpn | grep -E ':80 |:443 '        # кто занял веб-порты
docker ps --format '{{.Names}}\t{{.Ports}}'  # что публикуют соседние контейнеры
docker network ls --format '{{.Name}}' | xargs -I{} sh -c \
  'echo -n "{} "; docker network inspect {} -f "{{range .IPAM.Config}}{{.Subnet}} {{end}}"'
```

Читать вывод так:

**Порт 443 занят по UDP** (строка начинается с `udp`) — это нормально и нам не
мешает. Amnezia построена на WireGuard, а он работает по UDP. Наш прокси
слушает TCP, и HTTP/3, который тоже занял бы UDP 443, **отключён в Caddyfile
намеренно** — именно ради этого соседства.

**Порт 80 или 443 занят по TCP** — вот это конфликт. Варианты:

- если занял старый или ненужный сервис — освободить порт;
- если сервис нужен — поднять трекер на других портах, добавив в `.env`:

  ```ini
  HTTP_PORT=8080
  HTTPS_PORT=8443
  ```

  Цена: Let's Encrypt проверяет домен строго по 80-му порту, и на 8080 выдача
  сертификата не сработает. Тогда придётся либо ставить единый прокси перед
  обоими сервисами, либо переходить на проверку через DNS. Напиши мне, если
  окажется этот случай, — разберём отдельно.

**Подсети Docker.** Наш стек берёт `172.28.0.0/16`. Если он уже занят соседним
контейнером или пересекается с диапазоном VPN, поменяй в `.env`:

```ini
DOCKER_SUBNET=172.30.0.0/16
```

Пересечение подсетей — коварная штука: оно не роняет ничего сразу, а просто
делает часть адресов недостижимой, и разбираться потом тяжело.

**Имена контейнеров.** Наш стек живёт в проекте `sl-tracker`, имена получают
этот префикс. С контейнерами харнесса пересечься не должны, но взгляни на вывод
`docker ps` — если увидишь там что-то с таким же именем, скажи.

## 1. Своп, если памяти меньше 2 ГБ

Сборка Flutter Web съедает около двух гигабайт. На сервере с 1 ГБ её убьёт
система, причём сообщение будет невнятным — просто «Killed».

```bash
free -h                                    # сколько есть сейчас
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab   # переживёт перезагрузку
free -h                                    # проверка: своп появился
```

## 2. Адреса без покупки домена

Мы используем `sslip.io` — публичный DNS, который резолвит имя вида
`что-угодно.185-12-34-56.sslip.io` в адрес `185.12.34.56`. Для Let's Encrypt это
обычное доменное имя, сертификат выдаётся штатно.

Нужны два имени: приложение и хранилище вложений.

```
tracker.185-12-34-56.sslip.io
s3.185-12-34-56.sslip.io
```

Проверь, что они резолвятся в твой адрес (замени на свой):

```bash
getent hosts tracker.185-12-34-56.sslip.io
getent hosts s3.185-12-34-56.sslip.io
```

Обе команды должны вывести твой IP. Если пусто — DNS сервера не пускает
запросы наружу, скажи мне, подберём другой путь.

> Хранилище вынесено на отдельное имя намеренно: подпись ссылок S3 считается
> от хоста и пути, и префикс вида `/s3` внутри основного домена ломает проверку
> подписи на стороне MinIO.

## 3. Доступ сервера к репозиторию

Репозиторий приватный, поэтому серверу нужен свой ключ только на чтение.

```bash
ssh-keygen -t ed25519 -C "sl-tracker deploy" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
```

Выведенную строку добавь в GitHub: репозиторий → **Settings → Deploy keys → Add
deploy key**. Галочку «Allow write access» **не ставь** — серверу писать в
репозиторий незачем.

Проверка и клонирование:

```bash
ssh -T git@github.com          # должно поздороваться и упомянуть репозиторий
sudo mkdir -p /opt && sudo chown "$USER" /opt
git clone git@github.com:Vladislav-Zyuzko/sl-tracker.git /opt/sl-tracker
cd /opt/sl-tracker
git checkout develop
```

## 4. Приложение в Яндекс ID

В кабинете [oauth.yandex.ru](https://oauth.yandex.ru) у приложения, которое уже
заведено, добавь **второй** Redirect URI (локальный не удаляй — он нужен для разработки):

```
https://tracker.185-12-34-56.sslip.io/api/auth/yandex/callback
```

Адрес должен совпадать символ в символ с тем, что попадёт в `.env`.
Права остаются прежними: `login:info`, `login:email`, `login:avatar`.

## 5. Файл `.env`

```bash
cd /opt/sl-tracker
cp .env.example .env
```

Сгенерируй пароли — по одному на строку, каждый свой:

```bash
for n in POSTGRES_PASSWORD REDIS_PASSWORD MINIO_ROOT_PASSWORD SESSION_SECRET; do
  echo "$n=$(openssl rand -base64 32 | tr -d '/+=')"
done
```

Открой `.env` (`nano .env`) и заполни. Пароли — из вывода выше, адреса — свои:

```ini
POSTGRES_PASSWORD=<из вывода>
REDIS_PASSWORD=<из вывода>
MINIO_ROOT_PASSWORD=<из вывода>
SESSION_SECRET=<из вывода>

SL_DOMAIN=tracker.185-12-34-56.sslip.io
SL_S3_DOMAIN=s3.185-12-34-56.sslip.io
SL_ACME_EMAIL=твоя@почта
APP_BASE_URL=https://tracker.185-12-34-56.sslip.io
MINIO_PUBLIC_URL=https://s3.185-12-34-56.sslip.io
YANDEX_REDIRECT_URI=https://tracker.185-12-34-56.sslip.io/api/auth/yandex/callback

YANDEX_CLIENT_ID=<из кабинета Яндекса>
YANDEX_CLIENT_SECRET=<из кабинета Яндекса>

# Кого пускать в трекер. Без этого не войдёт никто, включая тебя.
# Адрес должен быть тем, который возвращает Яндекс в профиле.
ACCESS_LIST_BOOTSTRAP_EMAILS=твой@адрес,коллега@адрес,ещё-коллега@адрес
```

Проверь, что ничего не забыто и файл не попадёт в репозиторий:

```bash
grep -c 'change-me' .env      # должно быть 0
git check-ignore -v .env      # должно показать правило из .gitignore
chmod 600 .env                # читать может только владелец
```

> `APP_BASE_URL` обязан начинаться с `https://` — из его протокола выводится
> флаг `Secure` у cookie сессии. По `http://` кука уйдёт без него, и перехвативший
> трафик получит чужую сессию.

## 6. Первый запуск

```bash
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env build
```

Сборка клиента займёт 5–15 минут: внутри образа скачивается Flutter SDK
и компилируется приложение. Это происходит один раз, дальше слои кэшируются.

```bash
# Данные
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env up -d postgres redis minio
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env ps
```

Дождись, чтобы у всех трёх в колонке STATUS было **healthy**, а не просто running.

```bash
# Схема базы
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env --profile tools run --rm migrate

# Приложение
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env up -d api caddy
```

## 7. Проверка

```bash
# Изнутри: API жив, база и Redis отвечают
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env logs --tail=30 api

# Снаружи: сертификат выдан и приложение отвечает
curl -sS https://tracker.185-12-34-56.sslip.io/api/health
```

Ожидаемый ответ — `{"status":"ok","postgres":{"status":"up"...`.

Если Caddy не получил сертификат, смотри его логи:

```bash
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env logs --tail=50 caddy
```

Самые частые причины: закрыт 80-й порт, имя не резолвится, исчерпан лимит
Let's Encrypt после нескольких неудачных попыток подряд.

Дальше открой `https://tracker.185-12-34-56.sslip.io` в браузере и войди
через Яндекс ID. Если вход отказан — значит твоего адреса нет в
`ACCESS_LIST_BOOTSTRAP_EMAILS`; проверка идёт до создания сессии, и это защита,
а не поломка.

## 8. Ежедневные копии

```bash
mkdir -p /opt/sl-tracker/backups
./infra/scripts/backup-db.sh          # первый прогон вручную, убедиться что работает
crontab -e
```

Добавь строку:

```
0 4 * * * cd /opt/sl-tracker && ./infra/scripts/backup-db.sh >> backups/backup.log 2>&1
```

> Копия на том же сервере спасает от испорченных данных, но не от потери
> сервера. Раз в неделю забирай архив к себе:
> `scp server:/opt/sl-tracker/backups/db-*.sql.gz ./`

---

## Обновление версии

```bash
cd /opt/sl-tracker
./infra/scripts/deploy.sh
```

Скрипт забирает код, собирает образы, ждёт готовности базы, применяет миграции,
перезапускает приложение и проверяет, что оно ожило. При ошибке останавливается —
на сломанной базе приложение не поедет.

## Если что-то пошло не так

```bash
# Логи
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env logs --tail=100 api

# Откат на предыдущую версию кода
git log --oneline -10
git checkout <хеш>
./infra/scripts/deploy.sh

# Полная остановка (данные остаются)
docker compose -f infra/compose/docker-compose.prod.yml --env-file .env down
```

**Никогда не запускай `down -v`** на боевом сервере: `-v` удаляет тома, то есть
базу, вложения и сертификаты.

## Переезд на собственный домен

Когда купишь домен, ничего пересобирать не нужно:

1. Направь A-записи `tracker.` и `s3.` на IP сервера.
2. Поменяй в `.env` пять значений: `SL_DOMAIN`, `SL_S3_DOMAIN`, `APP_BASE_URL`,
   `MINIO_PUBLIC_URL`, `YANDEX_REDIRECT_URI`.
3. Добавь новый Redirect URI в кабинете Яндекса.
4. `./infra/scripts/deploy.sh`

Caddy выпустит сертификаты на новые имена сам. Старые ссылки на задачи
перестанут открываться — это цена смены домена, и она неизбежна.
