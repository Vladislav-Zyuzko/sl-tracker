import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'sl:auth:public';

/**
 * Снимает требование сессии с маршрута.
 *
 * Охрана сессии включена глобально: закрыто по умолчанию, открыто — явным решением.
 * Обратный порядок («вешаем охрану там, где вспомнили») рано или поздно оставляет
 * эндпоинт без проверки.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
