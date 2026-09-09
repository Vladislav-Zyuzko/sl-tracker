import { Module } from '@nestjs/common';
import { RealtimePublisher } from './realtime.publisher.js';

/**
 * Публикация живых обновлений.
 *
 * Модуль намеренно тощий и ни от кого не зависит, кроме Redis: его импортируют
 * доменные модули (задачи, комментарии, участники, уведомления, доступ), а он
 * не знает о них ничего. Сам WebSocket-сервер живёт в `RealtimeGatewayModule`,
 * который, наоборот, зависит от доменов — ради проверки прав. Разделение
 * не косметическое: без него получается цикл
 * `Issues → Notifications → Realtime → Issues`.
 */
@Module({
  providers: [RealtimePublisher],
  exports: [RealtimePublisher],
})
export class RealtimeModule {}
