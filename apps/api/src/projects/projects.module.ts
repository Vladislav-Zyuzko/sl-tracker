import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/index.js';
import { MembersController } from './members.controller.js';
import { MembersRepository } from './members.repository.js';
import { MembersService } from './members.service.js';
import { ProjectAccessService } from './project-access.service.js';
import { ProjectsController } from './projects.controller.js';
import { ProjectsRepository } from './projects.repository.js';
import { ProjectsService } from './projects.service.js';

/**
 * Проекты и участники (US-10 … US-18).
 *
 * `ProjectAccessService` экспортируется наружу: это единственная точка, где решается
 * «виден ли пользователю этот проект и что ему в нём можно». Приглашения и всё,
 * что появится внутри проекта, обязаны спрашивать разрешение здесь, а не заводить
 * собственную проверку членства.
 */
@Module({
  imports: [StorageModule],
  controllers: [ProjectsController, MembersController],
  providers: [
    ProjectsRepository,
    ProjectsService,
    ProjectAccessService,
    MembersRepository,
    MembersService,
  ],
  exports: [ProjectAccessService, ProjectsRepository, MembersRepository],
})
export class ProjectsModule {}
