# SPEC: PAT-эндпоинты SL Tracker

- **Статус:** спецификация к [`RFC-MCP-SERVER.md`](RFC-MCP-SERVER.md)
- **Исполнитель:** `sl-backend-engineer` (+ `sl-qa`; `sl-frontend-engineer` — экран)
- **Принцип:** все изменения строго аддитивные; существующие маршруты и поведение веб-клиента не меняются.
- **Ключевое решение пользователя:** машинной идентичности **нет** — токен принадлежит
  **участнику проекта** и наследует его права. Ни новых пользователей, ни членства, ни ролей
  заводить не нужно.

---

## 1. Схема БД

### 1.1 `apps/api/src/database/schema/enums.ts`

```ts
/** Назначение сессии: обычный вход/мобилка или персональный токен доступа. */
export const sessionPurposeEnum = pgEnum('session_purpose', ['session', 'pat']);
```

### 1.2 `apps/api/src/database/schema/sessions.ts`

Добавить три колонки и один индекс (существующие не трогать):

| Колонка | Тип | Правила |
|---|---|---|
| `label` | `varchar('label', { length: 64 })` | null — для cookie-сессий; у PAT обязательное человекочитаемое имя |
| `purpose` | `sessionPurposeEnum('purpose').notNull().default('session')` | `pat` — токен, выпущенный через `POST /api/tokens` |
| `tokenPrefix` | `varchar('token_prefix', { length: 12 })` | первые 8 символов предъявляемого токена: только для опознания в списке, **в проверке не участвует** |

Индекс: `index('sessions_user_purpose_idx').on(t.userId, t.purpose)` — выборка «мои токены».

Обновить doc-комментарий таблицы: PAT — та же сессия, что и вход, отличается назначением,
явным сроком и отсутствием скользящего продления.

### 1.3 Миграция

Сгенерировать `drizzle-kit` (`npm run db:generate` в `apps/api`) — файл вида
`src/database/migrations/0001_*.sql` + запись в `meta/_journal.json` и `meta/0001_snapshot.json`.
Эквивалент SQL для ревью:

```sql
CREATE TYPE "public"."session_purpose" AS ENUM('session', 'pat');
ALTER TABLE "sessions" ADD COLUMN "label" varchar(64);
ALTER TABLE "sessions" ADD COLUMN "purpose" "public"."session_purpose" DEFAULT 'session' NOT NULL;
ALTER TABLE "sessions" ADD COLUMN "token_prefix" varchar(12);
CREATE INDEX "sessions_user_purpose_idx" ON "sessions" USING btree ("user_id", "purpose");
```

Миграция безопасна на живой базе: только `ADD COLUMN` с дефолтом и новый тип.

## 2. `sessions` модуль

### 2.1 `session-token.ts`

```ts
/** Первые 8 символов предъявляемого токена: подпись для человека, не секрет и не проверка. */
export function tokenPrefix(token: string): string { return token.slice(0, 8); }
```

### 2.2 `session.service.ts`

| Метод | Изменение |
|---|---|
| `create(userId, kind, options?)` | новые опции `{ label?, purpose? = 'session', ttlSeconds? }`; при `purpose='pat'` срок берётся из `ttlSeconds` (или `null` = бессрочно), а не из `SESSION_TTL_SECONDS`; в `IssuedSession` добавить `prefix: tokenPrefix(token)` |
| `listForUser(userId, purpose)` | новый: список из БД (без Redis), сортировка по `createdAt desc`, без секрета |
| `revoke(id, actorUserId)` | новый: `revokedAt = now()` + удаление `sl:session:<id>` и id из `sl:sessions:by-user:<userId>`; идемпотентно; `actorUserId` обязателен и должен совпадать с владельцем токена |
| `countActive(userId, purpose)` | новый: для лимита активных PAT |
| `touch(session)` | **для `purpose='pat'` обновляет только `lastSeenAt`, `expiresAt` не двигает** |

`SessionRecord` (в `session.types.ts`) дополнить `label`, `purpose`, `prefix`.

## 3. Модуль `tokens` (`apps/api/src/tokens/`)

Структура как у соседних модулей: `tokens.module.ts`, `tokens.controller.ts`,
`tokens.service.ts`, `dto/`, `index.ts`; зарегистрировать в `app.module.ts`.
Контроллер под глобальным `SessionGuard` (никаких `@Public()`).

### 3.1 `POST /api/tokens` — выпустить токен себе

```ts
export class CreateTokenDto {
  @IsString() @Length(1, 64)
  name!: string;                       // «dsh-mcp», «ноутбук»

  @IsOptional() @IsInt() @Min(1) @Max(3650)
  expiresInDays?: number | null;       // null = бессрочно; отсутствует → 365
}
```

Правила:

1. Требуется **cookie-сессия** (`request.slAuth.session.kind === 'cookie'`) — иначе
   `403 { code: 'pat_cannot_manage_tokens' }`. Защита от размножения утечки: токеном нельзя
   выпустить новый токен.
2. Токен всегда выпускается **текущему пользователю** (`request.slAuth.user.id`). Параметра
   «выдать другому» нет — это осознанно: машинный доступ = доступ участника, вынесенный в токен.
3. Лимит активных PAT на пользователя — 20 → `409 { code: 'token_limit_reached' }`.
4. Rate limit — тем же декоратором/guard-ом, что у auth-маршрутов.
5. Ответ `201` (секрет показывается **единственный раз** за всю жизнь токена):

```json
{ "id": "uuid", "name": "dsh-mcp", "prefix": "3f9a1c22",
  "token": "3f9a1c22-…-….QmFzZTY0VmVyaWZpZXI", "expiresAt": "2027-09-24T00:00:00.000Z",
  "createdAt": "2026-09-24T00:00:00.000Z" }
```

### 3.2 `GET /api/tokens` — список своих токенов

Секрета в ответе нет ни при каких условиях; только `purpose='pat'`; по умолчанию без
отозванных (`?includeRevoked=true` — показать).

```json
{ "items": [ { "id": "uuid", "name": "dsh-mcp", "prefix": "3f9a1c22", "purpose": "pat",
               "createdAt": "…", "lastSeenAt": "…", "expiresAt": "…|null",
               "revokedAt": "…|null" } ], "total": 1 }
```

### 3.3 `DELETE /api/tokens/{id}` — отозвать

Только свой токен. Идемпотентно, ответ `204`. После отзыва первый же запрос с этим токеном
обязан получить `401 session_expired` (Redis-ключ удалён, `revokedAt` стоит).

### 3.4 Коды ошибок

| Код | HTTP | Когда |
|---|---|---|
| `pat_cannot_manage_tokens` | 403 | запрос с PAT на управление токенами |
| `token_limit_reached` | 409 | больше 20 активных PAT |
| `not_found` | 404 | токена нет, он не PAT или принадлежит другому пользователю |
| — | 401 | обычные правила guard-а |

Все ответы — в формате ошибок проекта (`code` + `message`), Swagger-аннотации обязательны.
Ни `GET`, ни `DELETE` не должны раскрывать существование чужого токена: для чужого id — `404`,
а не `403`.

## 4. Тесты (обязательный минимум для `sl-qa`)

**Юнит**

- `tokenPrefix` — стабилен и не зависит от длины токена.
- Валидация `CreateTokenDto`: имя 1..64, `expiresInDays` 1..3650 либо `null`.

**Интеграционные** (реальные Postgres + Redis тестового стенда)

1. `POST /api/tokens` из-под cookie → 201; `GET /api/me` с выданным токеном → 200 и **тот же `userId`**.
2. `GET /api/tokens` не содержит поля `token` и не отдаёт секрет ни в каком виде.
3. `DELETE /api/tokens/{id}` → 204; следующий запрос с токеном → 401 `session_expired`.
4. Запрос с PAT на `POST /api/tokens` → 403 `pat_cannot_manage_tokens`.
5. Чужой токен: `DELETE /api/tokens/{id}` другого пользователя → 404, токен продолжает работать у владельца.
6. **Скоуп = роль.** Владелец-`reader`: токен читает задачу (200), но `PATCH`/`POST comments` → 403;
   владелец-`member`: те же вызовы проходят, автор задачи/комментария — владелец токена.
7. `purpose='pat'` не продлевает `expiresAt` при использовании, но обновляет `lastSeenAt`.
8. Истёкший PAT (`expiresAt` в прошлом) → 401 `session_expired`.
9. Отзыв доступа владельцу (`DELETE /api/access-entries/{id}`) гасит его PAT: запрос → 401.

**E2E smoke**

Сценарий «MCP-путь»: создать задачу токеном → добавить комментарий → сменить статус →
прочитать задачу; автор — владелец токена, статус сменился.

## 5. Экран «Токены доступа» (frontend, отдельная задача)

- Место: профиль → раздел «Доступ» (рядом с настройками уведомлений).
- Список: имя, префикс (`3f9a1c22…`), создан, последний вход, срок/«бессрочно», статус.
- Создание: имя + срок (365 дней по умолчанию, пункт «бессрочно» с предупреждением) →
  **одноразовый** показ токена с кнопкой «Скопировать» и предупреждением «показывается один раз».
- Текст-предупреждение: «Токен даёт доступ к трекеру от вашего имени. Не передавайте его
  третьим лицам; при утечке отзовите его здесь».
- Отзыв: подтверждение → 204 → строка помечается отозванной.
- Состояния: пусто, ошибка 409 (лимит), 403, сеть.
- Дизайн — по `docs/design/system.md`; тексты — по `docs/design/flows.md`.

## 6. Документация, которую надо обновить

| Файл | Что |
|---|---|
| `docs/adr/0007-personal-access-tokens.md` | **новый ADR**: PAT как сессия с назначением, явный срок без продления, запрет PAT→PAT, токен принадлежит участнику (без отдельной машинной идентичности) |
| `docs/product/stories/auth.md` | история «токен доступа для машинного клиента» + критерии приёмки |
| `docs/api/openapi.json` | перегенерировать (артефакт сборки) |
| `CLAUDE.md` | ничего не менять: это задача, а не изменение правил проекта |

Переменных окружения новые правки **не добавляют** — ни `MCP_BOT_*`, ни каких-либо других.

## 7. Definition of Done

1. Все acceptance criteria из RFC §6 выполняются на живом инстансе.
2. Новые тесты зелёные; существующие тесты API не изменялись ради «подгонки».
3. В диффе нет ни одного места, где токен пишется в лог, в БД открытым текстом или в Redis.
4. Миграция проверена на копии боевой базы; откат — возврат предыдущего образа API
   (схема остаётся совместимой, колонки просто не используются).
5. Swagger описывает три новых маршрута, коды ошибок и формат «секрет показывается один раз».
