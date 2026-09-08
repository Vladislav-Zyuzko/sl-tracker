import { Module } from '@nestjs/common';
import { ProjectsModule } from '../projects/index.js';
import { QueueAccessService } from './queue-access.service.js';
import { ProjectQueuesController, QueueController } from './queues.controller.js';
import { QueuesRepository } from './queues.repository.js';
import { QueuesService } from './queues.service.js';

/**
 * Очереди и их статусы (US-30 … US-34, US-60).
 *
 * `ProjectsModule` импортируется ради `ProjectAccessService`: права на очередь
 * наследуются от роли в проекте, второй проверки членства быть не должно.
 *
 * `IssuesModule` здесь намеренно **не** импортируется: разбор ключа очереди —
 * статический метод `IssueKeyService`, а зависимость модулей идёт в одну сторону,
 * от задач к очередям. Обратная стрелка дала бы цикл.
 *
 * `QueueAccessService` экспортируется: список задач очереди и создание задачи
 * спрашивают разрешение здесь, а не заводят собственный поиск очереди по ключу.
 */
@Module({
  imports: [ProjectsModule],
  controllers: [ProjectQueuesController, QueueController],
  providers: [QueuesRepository, QueuesService, QueueAccessService],
  exports: [QueueAccessService, QueuesRepository],
})
export class QueuesModule {}
