import { spawn } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { API_DIR, E2E_ROOT, apiChildEnv, config } from './lib/config.mjs';
import { closeDb, truncateAll } from './lib/db.mjs';

/**
 * Запуск сквозного прогона.
 *
 *   1) поднимает отдельный экземпляр API на своём порту, своей базе и своей базе Redis;
 *   2) дожидается `/api/health` — не паузой, а опросом;
 *   3) чистит тестовую базу;
 *   4) запускает `node --test`;
 *   5) гасит API в любом случае, включая падение прогона.
 *
 * Внешний API можно подсунуть переменной `E2E_EXTERNAL_API=1` — тогда шаг 1 пропускается
 * и тесты идут по адресу из `E2E_API_URL`. Это нужно для прогона против стенда.
 */

const external = process.env.E2E_EXTERNAL_API === '1';
const apiEntry = resolve(API_DIR, 'dist/main.js');

let api;

function log(message) {
  process.stdout.write(`[e2e] ${message}\n`);
}

async function waitForHealth(timeoutMs = 60_000) {
  const deadline = Date.now() + timeoutMs;
  let lastError = 'нет ответа';
  while (Date.now() < deadline) {
    if (api && api.exitCode !== null) {
      throw new Error(`API завершился с кодом ${api.exitCode}, не успев подняться`);
    }
    try {
      const response = await fetch(`${config.apiBase}/health`, { signal: AbortSignal.timeout(2000) });
      if (response.ok) {
        return await response.json();
      }
      lastError = `HTTP ${response.status}`;
    } catch (error) {
      lastError = String(error.message ?? error);
    }
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(`API не поднялся за ${timeoutMs} мс: ${lastError}`);
}

/**
 * Ждёт собранный API.
 *
 * Ждёт, а не падает сразу: пока над `apps/api` работает инженер, `npm run build`
 * на несколько секунд убирает `dist/` целиком. Прогон, падающий из-за чужой сборки,
 * ничего не сообщает о продукте.
 */
async function waitForApiBuild(timeoutMs = 90_000) {
  if (existsSync(apiEntry)) {
    return;
  }
  log(`жду сборку API (${apiEntry})`);
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 500));
    if (existsSync(apiEntry)) {
      // Файл мог появиться раньше, чем сборка дописала остальные модули.
      await new Promise((r) => setTimeout(r, 1500));
      return;
    }
  }
  throw new Error(`Нет собранного API (${apiEntry}). Собери его: cd apps/api && npm run build`);
}

async function startApi() {
  if (external) {
    log(`внешний API: ${config.apiUrl}`);
    return;
  }

  await waitForApiBuild();

  log(
    `поднимаю API: порт ${config.apiPort}, база ${config.postgres.database}, ` +
      `Redis ${config.redis.db}, bucket ${config.minioBucket}`,
  );

  api = spawn(process.execPath, [apiEntry], {
    cwd: API_DIR,
    env: apiChildEnv(),
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  const prefix = (stream, tag) => {
    stream.setEncoding('utf8');
    stream.on('data', (chunk) => {
      if (process.env.E2E_API_LOG === '1') {
        for (const line of chunk.split(/\r?\n/)) {
          if (line.trim()) process.stdout.write(`[api ${tag}] ${line}\n`);
        }
      }
    });
  };
  prefix(api.stdout, 'out');
  prefix(api.stderr, 'err');

  const health = await waitForHealth();
  log(`API отвечает: ${JSON.stringify(health)}`);
}

function stopApi() {
  if (api && api.exitCode === null) {
    api.kill();
  }
}

async function runTests() {
  // `--test-concurrency=1`: файлы идут по одному. Они делят один API, одну базу и одни
  // счётчики ограничения частоты, поэтому параллельный прогон files даёт ложные падения.
  // `--test-timeout`: зависший тест обязан упасть с указанием места, а не висеть вечно.
  const args = [
    '--test',
    '--test-concurrency=1',
    `--test-timeout=${process.env.E2E_TEST_TIMEOUT ?? 120_000}`,
    // Без этого прогон нескольких файлов встаёт на 3 минуты после каждого файла,
    // который много ходил по HTTP: `fetch` держит соединения в пуле keep-alive,
    // процесс файла из-за них не завершается, а раннер ждёт его завершения, прежде
    // чем взять следующий файл. Закрыть пул из теста нечем: Node не отдаёт наружу
    // диспетчер своего `fetch`. Флаг завершает процесс, когда тесты кончились, —
    // ровно то поведение, которое здесь нужно.
    '--test-force-exit',
  ];
  if (process.env.E2E_TEST_NAME) {
    args.push('--test-name-pattern', process.env.E2E_TEST_NAME);
  }
  // Файлы перечисляются явно: `node --test tests/` на Windows пытается загрузить
  // каталог как модуль вместо обхода, а полагаться на раскрытие шаблона нечем —
  // раннер запускается и из cmd, и из PowerShell, и из bash.
  const files = process.argv.slice(2);
  const suite =
    files.length > 0
      ? files
      : readdirSync(resolve(E2E_ROOT, 'tests'))
          .filter((name) => name.endsWith('.test.mjs'))
          .sort()
          .map((name) => `tests/${name}`);
  args.push(...suite);

  log(`node ${args.join(' ')}`);

  return new Promise((resolvePromise) => {
    const child = spawn(process.execPath, args, {
      cwd: E2E_ROOT,
      env: { ...process.env, ...envForTests() },
      stdio: 'inherit',
    });
    child.on('exit', (code) => resolvePromise(code ?? 1));
  });
}

/** Тестовым процессам нужен тот же адрес API и та же база, что и раннеру. */
function envForTests() {
  return {
    E2E_API_URL: config.apiUrl,
    E2E_APP_BASE_URL: config.appBaseUrl,
    E2E_POSTGRES_DB: config.postgres.database,
    E2E_REDIS_DB: String(config.redis.db),
  };
}

let exitCode = 1;
try {
  await startApi();
  log('чищу тестовую базу');
  await truncateAll();
  await closeDb();
  exitCode = await runTests();
} catch (error) {
  process.stderr.write(`[e2e] ${error.stack ?? error}\n`);
  exitCode = 1;
} finally {
  stopApi();
  await closeDb().catch(() => {});
}

process.exit(exitCode);
