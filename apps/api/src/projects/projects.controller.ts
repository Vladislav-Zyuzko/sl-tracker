import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  PayloadTooLargeException,
  Post,
  Put,
  Query,
  Req,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiConflictResponse,
  ApiConsumes,
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiPayloadTooLargeResponse,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { FastifyRequest } from 'fastify';
import { CurrentUser } from '../auth/index.js';
import type { AuthenticatedUser } from '../auth/index.js';
import { COVER_ALLOWED_TYPES, COVER_MAX_BYTES } from '../storage/index.js';
import {
  CreateProjectDto,
  ListProjectsQueryDto,
  UpdateProjectDto,
  UpdateProjectSlugDto,
} from './dto/project-input.dto.js';
import { ProjectDto, ProjectListDto } from './dto/project.dto.js';
import { ProjectsService } from './projects.service.js';

/**
 * Проекты (US-10 … US-18). Контроллер не знает ни про SQL, ни про хранилище файлов:
 * он разбирает HTTP и отдаёт DTO.
 *
 * Ответ на обращение к чужому или несуществующему проекту — всегда 404: не-участник
 * не должен узнать о существовании проекта (permissions.md, п. 5).
 */
@ApiTags('projects')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projects: ProjectsService) {}

  @Get()
  @ApiOperation({
    summary: 'Мои проекты',
    description:
      'Проекты, где пользователь состоит в любой роли, по названию по возрастанию. ' +
      'Чужие проекты в список не попадают, даже если известен их адрес (US-10).',
  })
  @ApiOkResponse({ type: ProjectListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Query() query: ListProjectsQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectListDto> {
    const page = await this.projects.listForUser(actor, {
      limit: query.limit,
      cursor: query.cursor,
    });

    return {
      items: page.items.map((view) => ProjectDto.from(view)),
      nextCursor: page.nextCursor,
      total: page.total,
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Создать проект',
    description:
      'Создать проект может любой пользователь, прошедший список доступа; отдельного ' +
      'права нет. Создатель становится администратором и единственным участником (US-11).\n\n' +
      '**Короткое имя в адресе выдаёт сервер** по названию: кириллица транслитерируется ' +
      '(`и` → `i`, `й` → `y`, `ж` → `zh`, `ч` → `ch`, `ш` → `sh`, `щ` → `sch`, `ю` → `yu`, ' +
      '`я` → `ya`, `ь` и `ъ` пропадают), регистр приводится к нижнему, всё недопустимое ' +
      'заменяется дефисом, повторные дефисы схлопываются, крайние обрезаются, длина ' +
      'ограничена 40 символами. «Сладкий Лимит 2026!» → `sladkiy-limit-2026`. Если ' +
      'допустимых символов не осталось, имя будет вида `project-7`. При коллизии ' +
      'добавляется числовой суффикс (`sladkiy-limit-2`), поэтому предпросмотр на клиенте ' +
      'может разойтись с итогом: окончательное значение всегда в поле `slug` ответа.',
  })
  @ApiCreatedResponse({ type: ProjectDto })
  @ApiBadRequestResponse({ description: 'Пустое название (`invalid_project_name`)' })
  async create(
    @Body() body: CreateProjectDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectDto> {
    const created = await this.projects.create(body, actor);
    return ProjectDto.from(created);
  }

  @Get(':slug')
  @ApiOperation({
    summary: 'Проект по короткому имени',
    description:
      'Работает и для прежних коротких имён проекта: в ответе всегда действующее `slug`, ' +
      'и клиент заменяет им адрес в строке браузера (US-18). Не-участник получает 404 ' +
      'без каких-либо данных проекта.',
  })
  @ApiParam({ name: 'slug', example: 'sladkiy-limit' })
  @ApiOkResponse({ type: ProjectDto })
  @ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
  async get(
    @Param('slug') slug: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectDto> {
    return ProjectDto.from(await this.projects.getBySlug(slug, actor));
  }

  @Patch(':slug')
  @ApiOperation({
    summary: 'Изменить название и описание',
    description:
      'Только администратор проекта. Переименование **не меняет** короткое имя в адресе: ' +
      'ранее отправленные ссылки продолжают работать (US-18).',
  })
  @ApiOkResponse({ type: ProjectDto })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
  async update(
    @Param('slug') slug: string,
    @Body() body: UpdateProjectDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectDto> {
    return ProjectDto.from(await this.projects.updateDetails(slug, body, actor));
  }

  @Put(':slug/slug')
  @ApiOperation({
    summary: 'Изменить короткое имя в адресе',
    description:
      'Только администратор и только явным действием (US-18). Прежнее короткое имя ' +
      'остаётся занятым навсегда и продолжает открывать этот же проект; другому проекту ' +
      'оно достаться не может. Системные адреса приложения (`issues`, `invite`, `projects`, ' +
      '`profile`, `me`, `api`, `login`, `access-denied`, `notifications`, `queues`) ' +
      'отклоняются.',
  })
  @ApiOkResponse({ type: ProjectDto })
  @ApiBadRequestResponse({ description: 'Недопустимый вид имени (`invalid_slug`)' })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiConflictResponse({
    description: 'Имя занято (`slug_taken`) или зарезервировано приложением (`reserved_slug`)',
  })
  @ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
  async changeSlug(
    @Param('slug') slug: string,
    @Body() body: UpdateProjectSlugDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectDto> {
    return ProjectDto.from(await this.projects.changeSlug(slug, body.slug, actor));
  }

  @Delete(':slug')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Удалить проект',
    description:
      'Только администратор (US-17). Удаляются очереди, задачи, комментарии и вложения. ' +
      'Ключи очередей и прежние короткие имена остаются занятыми и повторно не выдаются ' +
      '(D-25, US-18).',
  })
  @ApiNoContentResponse({ description: 'Проект удалён' })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
  async remove(
    @Param('slug') slug: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<void> {
    await this.projects.remove(slug, actor);
  }

  @Put(':slug/cover')
  @ApiOperation({
    summary: 'Загрузить обложку проекта',
    description:
      'Только администратор. Один файл в поле `file`: PNG, JPEG или WEBP до 5 МБ (US-12). ' +
      'Тип определяется по содержимому файла, а не по заголовку и не по расширению; ' +
      'имя объекта в хранилище генерирует сервер. Загрузка второй обложки заменяет ' +
      'предыдущую. Обложка отдаётся подписанной ссылкой в поле `coverUrl` и по прямой ' +
      'ссылке без подписи недоступна.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOkResponse({ type: ProjectDto })
  @ApiBadRequestResponse({
    description:
      'Файла нет (`cover_file_required`) или тип не поддержан (`cover_unsupported_type`)',
  })
  @ApiPayloadTooLargeResponse({ description: 'Файл больше 5 МБ (`cover_too_large`)' })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
  async uploadCover(
    @Param('slug') slug: string,
    @Req() request: FastifyRequest,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectDto> {
    const file = await readSingleFile(request);
    return ProjectDto.from(await this.projects.setCover(slug, file, actor));
  }

  @Delete(':slug/cover')
  @ApiOperation({
    summary: 'Удалить обложку проекта',
    description: 'Только администратор. В списке и в шапке снова показывается заглушка (US-12).',
  })
  @ApiOkResponse({ type: ProjectDto })
  @ApiForbiddenResponse({ description: 'Не администратор проекта (`project_forbidden`)' })
  @ApiNotFoundResponse({ description: 'Проекта нет или пользователь не участник' })
  async removeCover(
    @Param('slug') slug: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<ProjectDto> {
    return ProjectDto.from(await this.projects.removeCover(slug, actor));
  }
}

/**
 * Читает единственный файл из multipart-запроса.
 *
 * Ограничение по размеру задаётся здесь, на маршруте, а не глобально: у вложений
 * к задачам оно другое (25 МБ, D-21). Файл читается в память целиком — 5 МБ это
 * допускают, и хранилищу всё равно нужна длина содержимого.
 */
async function readSingleFile(
  request: FastifyRequest,
): Promise<{ buffer: Buffer; truncated: boolean }> {
  if (!request.isMultipart()) {
    throw new BadRequestException({
      code: 'cover_file_required',
      message: 'Ожидается multipart/form-data с полем file',
    });
  }

  const file = await request.file({ limits: { fileSize: COVER_MAX_BYTES, files: 1 } });
  if (!file) {
    throw new BadRequestException({
      code: 'cover_file_required',
      message: 'Файл не передан',
    });
  }

  try {
    const buffer = await file.toBuffer();
    return { buffer, truncated: file.file.truncated };
  } catch {
    // Единственная ожидаемая здесь ошибка — превышение лимита размера потоком.
    throw new PayloadTooLargeException({
      code: 'cover_too_large',
      message: `Допустимы ${COVER_ALLOWED_TYPES.join(', ')} до 5 МБ`,
    });
  }
}
