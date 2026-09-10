import { config } from './config.mjs';

/**
 * HTTP-клиент сквозных тестов.
 *
 * Ведёт себя как браузер веб-клиента: сессия предъявляется cookie `sl_session`,
 * а небезопасные методы несут заголовок `Origin` — без него API отвечает 403
 * (`csrf_origin_mismatch`, см. `apps/api/src/auth/csrf.ts`). Это не удобство
 * харнесса: тест, ходящий bearer-токеном, не проверил бы веб-путь вовсе.
 *
 * Клиент никогда не бросает исключение по коду ответа. Ответ — это данные:
 * ожидание кода принадлежит тесту, а не транспорту, иначе негативные сценарии
 * пришлось бы писать через try/catch.
 */

const SESSION_COOKIE = 'sl_session';

export class ApiClient {
  /**
   * @param {object} options
   * @param {string} [options.token] секрет сессии; без него клиент анонимный
   * @param {string} [options.label] имя в сообщениях об ошибках
   * @param {'cookie'|'bearer'} [options.presentAs] способ предъявления сессии
   */
  constructor({ token, label = 'anonymous', presentAs = 'cookie' } = {}) {
    this.token = token;
    this.label = label;
    this.presentAs = presentAs;
    /** Заголовок Origin. `null` — не отправлять вовсе (проверка CSRF). */
    this.origin = config.appOrigin;
  }

  withoutOrigin() {
    const copy = new ApiClient({ token: this.token, label: this.label, presentAs: this.presentAs });
    copy.origin = null;
    return copy;
  }

  withOrigin(origin) {
    const copy = new ApiClient({ token: this.token, label: this.label, presentAs: this.presentAs });
    copy.origin = origin;
    return copy;
  }

  async request(method, path, { body, headers = {}, raw, query } = {}) {
    const url = new URL(path.startsWith('http') ? path : `${config.apiBase}${path}`);
    for (const [key, value] of Object.entries(query ?? {})) {
      if (value !== undefined && value !== null) {
        url.searchParams.set(key, String(value));
      }
    }

    const requestHeaders = { accept: 'application/json', ...headers };

    if (this.token) {
      if (this.presentAs === 'bearer') {
        requestHeaders.authorization = `Bearer ${this.token}`;
      } else {
        requestHeaders.cookie = `${SESSION_COOKIE}=${this.token}`;
      }
    }

    if (this.origin !== null) {
      requestHeaders.origin = this.origin;
    }

    let payload = raw;
    if (body !== undefined) {
      requestHeaders['content-type'] = 'application/json';
      payload = JSON.stringify(body);
    }

    const response = await fetch(url, {
      method,
      headers: requestHeaders,
      body: payload,
      redirect: 'manual',
    });

    const text = await response.text();
    let parsed = null;
    if (text.length > 0) {
      try {
        parsed = JSON.parse(text);
      } catch {
        parsed = text;
      }
    }

    return new ApiResponse(method, url.pathname + url.search, response, parsed);
  }

  get(path, options) {
    return this.request('GET', path, options);
  }
  post(path, body, options) {
    return this.request('POST', path, { ...options, body });
  }
  patch(path, body, options) {
    return this.request('PATCH', path, { ...options, body });
  }
  put(path, body, options) {
    return this.request('PUT', path, { ...options, body });
  }
  delete(path, options) {
    return this.request('DELETE', path, options);
  }

  /** Загрузка файла: multipart, как это делает браузер. */
  async upload(path, { filename, contentType, bytes, field = 'file' }) {
    const form = new FormData();
    form.append(field, new Blob([bytes], { type: contentType }), filename);
    return this.request('POST', path, { raw: form });
  }
}

export class ApiResponse {
  constructor(method, path, response, body) {
    this.method = method;
    this.path = path;
    this.status = response.status;
    this.headers = response.headers;
    this.body = body;
  }

  /** Код ошибки из тела (`{ code, message }`) — по нему тесты и отличают отказы. */
  get code() {
    return this.body && typeof this.body === 'object' ? this.body.code : undefined;
  }

  /**
   * Проверяет код ответа и возвращает тело. Сообщение об ошибке несёт настоящий
   * ответ сервера — иначе падение теста приходится расследовать вручную.
   */
  expect(...statuses) {
    if (!statuses.includes(this.status)) {
      throw new Error(
        `${this.method} ${this.path}: ожидался код ${statuses.join(' или ')}, получен ${this.status}\n` +
          `тело: ${JSON.stringify(this.body)}`,
      );
    }
    return this.body;
  }
}

/** Анонимный клиент: ни cookie, ни заголовка Authorization. */
export function anonymous() {
  return new ApiClient({ label: 'anonymous' });
}
