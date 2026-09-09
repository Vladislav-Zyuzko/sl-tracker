import { Module } from '@nestjs/common';
import { AccessModule } from './access/index.js';
import { AttachmentsModule } from './attachments/index.js';
import { AuthModule } from './auth/index.js';
import { CommentsModule } from './comments/index.js';
import { ConfigModule } from './config/index.js';
import { DatabaseModule } from './database/index.js';
import { HealthModule } from './health/health.module.js';
import { InvitationsModule } from './invitations/index.js';
import { IssuesModule } from './issues/index.js';
import { MentionsModule } from './mentions/index.js';
import { NotificationsModule } from './notifications/index.js';
import { ProjectsModule } from './projects/index.js';
import { QueuesModule } from './queues/index.js';
import { RealtimeGatewayModule } from './realtime/index.js';
import { RedisModule } from './redis/index.js';
import { SessionsModule } from './sessions/index.js';

/**
 * Корневой модуль. Структура — по доменам: каждый домен приносит свои контроллеры,
 * сервисы и репозитории. Инфраструктурные модули (конфигурация, БД, Redis) глобальны,
 * чтобы не тянуть их импортом в каждый доменный модуль.
 */
@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    RedisModule,
    SessionsModule,
    AccessModule,
    AuthModule,
    HealthModule,
    ProjectsModule,
    InvitationsModule,
    QueuesModule,
    IssuesModule,
    MentionsModule,
    CommentsModule,
    AttachmentsModule,
    NotificationsModule,
    RealtimeGatewayModule,
  ],
})
export class AppModule {}
