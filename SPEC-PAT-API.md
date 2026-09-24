# SPEC: PAT-эндпоинты и бот-пользователь для MCP

- **Статус:** спецификация к [`RFC-MCP-SERVER.md`](RFC-MCP-SERVER.md)
- **Исполнитель:** `sl-backend-engineer` (+ `sl-qa`, `sl-frontend-engineer` для экрана)
- **Принцип:** все изменения строго аддитивные; существующие маршруты и поведение веб-клиента не меняются.

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
| `revoke(id, actorUserId?)` | новый: `revokedAt = now()` + удаление `sl:session:<id>` и id из `sl:sessions:by-user:<userId>`; идемпотентно |
| `countActive(userId, purpose)` | новый: для лимита активных PAT |
| `touch(session)` | **для `purpose='pat'` обновляет только `lastSeenAt`, `expiresAt` не двигает** |

`SessionRecord` (в `session.types.ts`) дополнить `label`, `purpose`, `prefix`.

## 3. Модуль `tokens` (`apps/api/src/tokens/`)

Структура как у соседних модулей: `tokens.module.ts`, `tokens.controller.ts`,
`tokens.service.ts`, `dto/`, `index.ts`; зарегистрировать в `app.module.ts`.
Контроллер под глобальным `SessionGuard` (никаких `@Public()`).

### 3.1 `POST /api/tokens` — выпустить токен

```ts
export class CreateTokenDto {
  @IsString() @Length(1, 64)
  name!: string;                       // «dsh-mcp», «ноутбук»

  @IsOptional() @IsInt() @Min(1) @Max(3650)
  expiresInDays?: number | null;       // null = бессрочно; отсутствует → 365

  @IsOptional() @IsUUID()
  userId?: string;                     // только владелец инстанса: выпустить токен боту
}
```

Правила:

1. Требуется **cookie-сессия** (`request.slAuth.session.kind === 'cookie'`) — иначе
   `403 { code: 'pat_cannot_manage_tokens' }`. Это защита от размножения утечки.
2. `userId` разрешён только `isInstanceOwner` — иначе `403 { code: 'forbidden_scope' }`.
3. Лимит активных PAT на пользователя — 20 → `409 { code: 'token_limit_reached' }`.
4. Rate limit — тем же декоратором/guard-ом, что у auth-маршрутов.
5. Ответ `201` (секрет показывается **единственный раз** за всю жизнь токена):

```json
{ "id": "uuid", "name": "dsh-mcp", "prefix": "3f9a1c22",
  "token": "3f9a1c22-…-….QmFzZTY0VmVyaWZpZXI", "expiresAt": "2027-09-24T00:00:00.000Z",
  "createdAt": "2026-09-24T00:00:00.000Z" }
```

### 3.2 `GET /api/tokens` — список

Свои токены; владельцу доступен `?userId=<uuid>`. Секрета в ответе нет ни при каких условиях:

```json
{ "items": [ { "id": "uuid", "name": "dsh-mcp", "prefix": "3f9a1c22", "purpose": "pat",
               "createdAt": "…", "lastSeenAt": "…", "expiresAt": "…|null",
               "revokedAt": "…|null" } ], "total": 1 }
```

Только `purpose='pat'` и, по умолчанию, без отозванных (`?includeRevoked=true` — показать).

### 3.3 `DELETE /api/tokens/{id}` — отозвать

Свой токен или (владелец) любой. Идемпотентно, ответ `204`. После отзыва первый же запрос
с этим токеном обязан получить `401 session_expired` (Redis-ключ удалён, `revokedAt` стоит).

### 3.4 Коды ошибок

| Код | HTTP | Когда |
|---|---|---|
| `pat_cannot_manage_tokens` | 403 | запрос с PAT на управление токенами |
| `forbidden_scope` | 403 | не владелец пытается выпустить/отозвать чужой токен |
| `token_limit_reached` | 409 | больше 20 активных PAT |
| `not_found` | 404 | токена нет или он не PAT |
| — | 401 | обычные правила guard-а |

Все ответы — в формате ошибок проекта (`code` + `message`), Swagger-аннотации обязательны.

## 4. Бот-пользователь (bootstrap из env)

### 4.1 Переменные (`config/env.schema.ts`, `.env.example`)

```ts
MCP_BOT_EMAIL: z.email().optional(),                                        // пусто → bootstrap выключен
MCP_BOT_DISPLAY_NAME: z.string().min(1).max(255).optional(),                // по умолчанию «SL Bot»
MCP_BOT_PROJECTS: z.string().optional(),                                    // слаги через запятую: sl-tracker,home
MCP_BOT_PROJECT_ROLE: z.enum(['admin','member','reader']).default('member'),
```

### 4.2 Сервис `apps/api/src/mcp-bot/mcp-bot-bootstrap.service.ts`

`OnApplicationBootstrap`, по образцу `AccessBootstrapService` (идемпотентность, «источник
правды — БД», тихий выход при пустом env):

1. **Пользователь.** Найти по `lower(email)` или создать `users`:
   `displayName = MCP_BOT_DISPLAY_NAME ?? 'SL Bot'`, `avatarUrl = null`, `lastLoginAt = null`.
   **`identities` не создавать** — бот никогда не логинится.
2. **Список доступа.** Найти/создать `access_entries` для этого email:
   `source = 'config'`, `isInstanceOwner = false`, `userId` = созданный пользователь.
   Существующую запись не перезаписывать (как в access-bootstrap).
3. **Членство.** Для каждого слага из `MCP_BOT_PROJECTS`: найти проект; если нет — warning
   и продолжать (не падать). Если членства нет — вставить `project_members`
   (`role = MCP_BOT_PROJECT_ROLE`); существующее членство **не менять** (ручное решение
   человека важнее env).
4. **Логи.** Только факты и количество: «бот готов: projects=2, role=member». Email и любые
   секреты в логи не писать.

Границы: удаление переменной из env ничего не удаляет (отзыв — через экран доступа);
повторный запуск не создаёт дублей; ошибка bootstrap не должна ронять старт API.

## 5. Тесты (обязательный минимум для `sl-qa`)

**Юнит**

- `tokenPrefix` и `parseBotProjects` (мусор/дубликаты/пробелы схлопываются, как в `parseBootstrapEmails`).
- Валидация `CreateTokenDto`: имя 1..64, `expiresInDays` 1..3650 либо `null`.

**Интеграционные** (реальные Postgres + Redis тестового стенда)

1. `POST /api/tokens` из-под cookie → 201, `GET /api/me` с выданным токеном → 200, тот же `userId`.
2. `GET /api/tokens` не содержит поля `token` и не отдаёт секрет ни в каком виде.
3. `DELETE /api/tokens/{id}` → 204, следующий запрос с токеном → 401 `session_expired`.
4. Запрос с PAT на `POST /api/tokens` → 403 `pat_cannot_manage_tokens`.
5. Не-владелец с `userId` другого пользователя → 403 `forbidden_scope`.
6. Владелец выпускает токен боту → бот может создать задачу в проекте, где он участник.
7. Bootstrap идемпотентен: два старта → одна запись `users`, одна `access_entries`, одно `project_members`.
8. `purpose='pat'` не продлевает `expiresAt` при использовании, но обновляет `lastSeenAt`.
9. Отзыв доступа бота (`DELETE /api/access-entries/{id}`) гасит его PAT: запрос → 401.

**E2E smoke**

Сценарий «MCP-путь»: создать задачу ботом → добавить комментарий → сменить статус → прочитать
задачу; проверить, что автор — бот, а статус сменился.

## 6. Экран «Токены доступа» (frontend, отдельная задача)

- Место: профиль → раздел «Доступ» (рядом с настройками уведомлений).
- Список: имя, префикс (`3f9a1c22…`), создан, последний вход, срок/«бессрочно», статус.
- Создание: имя + срок (365 дней по умолчанию, пункт «бессрочно» с предупреждением) →
  **одноразовый** показ токена с кнопкой «Скопировать» и предупреждением «показывается один раз».
- Отзыв: подтверждение → 204 → строка помечается отозванной.
- Состояния: пусто, ошибка 409 (лимит), 403 (нет прав), сеть.
- Дизайн — по `docs/design/system.md`; тексты — по `docs/design/flows.md`.

## 7. Документация, которую надо обновить

| Файл | Что |
|---|---|
| `docs/adr/0007-personal-access-tokens.md` | **новый ADR**: PAT как сессия с назначением, явный срок, запрет PAT→PAT, бот из env |
| `docs/product/stories/auth.md` | история «токен доступа для машинного клиента» + критерии приёмки |
| `.env.example` | `MCP_BOT_EMAIL`, `MCP_BOT_DISPLAY_NAME`, `MCP_BOT_PROJECTS`, `MCP_BOT_PROJECT_ROLE` |
| `docs/api/openapi.json` | перегенерировать (артефакт сборки) |
| `CLAUDE.md` | ничего не менять: это задача, а не изменение правил проекта |

## 8. Definition of Done

1. Все acceptance criteria из RFC §6 выполняются на живом инстансе.
2. Новые тесты зелёные; существующие тесты API не изменялись ради «подгонки».
3. В диффе нет ни одного места, где токен пишется в лог, в БД открытым текстом или в Redis.
4. Миграция проверена на копии боевой базы; откат — возврат предыдущего образа API
   (схема остаётся совместимой, колонки просто не используются).
5. Swagger описывает три новых маршрута, коды ошибок и формат «секрет показывается один раз».
