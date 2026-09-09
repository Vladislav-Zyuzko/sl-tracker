import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/index.js';
import { IssuesModule } from '../issues/index.js';
import { ProjectsModule } from '../projects/index.js';
import { SessionsModule } from '../sessions/index.js';
import { RealtimeGateway } from './realtime.gateway.js';

/**
 * WebSocket-сервер живых обновлений.
 *
 * Импортируется только корневым модулем — и это важно: здесь зависимости идут
 * в доменные модули (проверка прав на задачу и на проект), а публикация событий
 * живёт в отдельном `RealtimeModule`, у которого зависимостей нет. Иначе получился бы
 * цикл `Issues → Notifications → Realtime → Issues`.
 *
 * `AuthModule` нужен ради `AuthRepository`: пользователь читается из БД на каждом
 * рукопожатии, как и на каждом HTTP-запросе.
 */
@Module({
  imports: [SessionsModule, AuthModule, IssuesModule, ProjectsModule],
  providers: [RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeGatewayModule {}
