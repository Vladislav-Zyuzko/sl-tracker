import { SetMetadata } from '@nestjs/common';

export const RATE_LIMIT_KEY = 'sl:auth:rate-limit';

export interface RateLimitOptions {
  /** Сколько запросов разрешено в окне. */
  limit: number;
  /** Длина окна в секундах. */
  windowSeconds: number;
  /** Имя корзины: маршруты с одним именем делят счётчик. */
  name: string;
}

/**
 * Ограничение частоты для маршрута. Обязательно на `/api/auth/*` и на поиске:
 * без него колбэк и старт входа — бесплатный генератор нагрузки на Яндекс и на Redis.
 */
export const RateLimit = (options: RateLimitOptions) => SetMetadata(RATE_LIMIT_KEY, options);
