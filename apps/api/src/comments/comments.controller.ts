import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/index.js';
import type { AuthenticatedUser } from '../auth/index.js';
import { CommentsService } from './comments.service.js';
import {
  CommentDto,
  CommentListDto,
  CreateCommentDto,
  ListCommentsQueryDto,
  UpdateCommentDto,
} from './dto/comment.dto.js';

/**
 * Комментарии к задаче (US-70 … US-73).
 *
 * Адресуются ключом задачи, как и сама задача. Не-участник проекта получает 404
 * без единого поля — и задачи, и её обсуждения (permissions.md, п. 5).
 */
@ApiTags('comments')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Задачи нет или пользователь не участник проекта' })
@Controller('issues/:key/comments')
export class CommentsController {
  constructor(private readonly comments: CommentsService) {}

  @Get()
  @ApiOperation({
    summary: 'Комментарии задачи',
    description:
      'Плоская лента в хронологическом порядке, **сначала старые** (US-70). Видна всем ' +
      'участникам проекта, включая читателя.\n\n' +
      'Пагинация идёт **назад по времени**: запрос без курсора отдаёт последние ' +
      '`limit` комментариев, а `nextCursor` ведёт к более ранним — это кнопка ' +
      '«Показать более ранние» над лентой. `limit` по умолчанию 50, жёсткий ' +
      'максимум 100.\n\n' +
      'Автор каждого комментария и упомянутые в нём участники приходят сразу: ' +
      'второй запрос за именами и аватарами не нужен.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42', description: 'Ключ задачи, регистронезависим' })
  @ApiOkResponse({ type: CommentListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Param('key') key: string,
    @Query() query: ListCommentsQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<CommentListDto> {
    const page = await this.comments.list(key, actor, {
      limit: query.limit,
      cursor: query.cursor,
    });

    return {
      items: page.items.map((row) =>
        CommentDto.from(row, { role: page.context.role, actorId: actor.id }),
      ),
      nextCursor: page.nextCursor,
      total: page.total,
      canComment: page.context.role !== 'reader',
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Написать комментарий',
    description:
      'Администратор и участник проекта; читатель — 403 (US-71, D-29). Пустой текст ' +
      'и текст из одних пробелов отклоняются, максимум — 10 000 символов.\n\n' +
      'Автор комментария становится подписчиком задачи и дальше получает уведомления ' +
      'по ней (D-17). Подписчики задачи, кроме автора комментария, получают уведомление ' +
      '(US-102); упомянутые — уведомление об упоминании вместо него, то есть **одно, ' +
      'а не два** (US-104).\n\n' +
      'Упоминание записывается токеном `@[Имя](user:<uuid>)`. Упомянуть можно **только ' +
      'участника проекта задачи**: токен с посторонним игнорируется молча — без ошибки, ' +
      'без связи и без уведомления (D-41, ADR-0006, п. 6).',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiCreatedResponse({ type: CommentDto })
  @ApiBadRequestResponse({
    description: 'Пустой или слишком длинный текст (`invalid_comment_body`)',
  })
  @ApiForbiddenResponse({ description: 'Читатель не комментирует (`comment_forbidden`)' })
  async create(
    @Param('key') key: string,
    @Body() body: CreateCommentDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<CommentDto> {
    const view = await this.comments.create(key, body.body, actor);
    return CommentDto.from(view.comment, { role: view.context.role, actorId: actor.id });
  }

  @Patch(':commentId')
  @ApiOperation({
    summary: 'Изменить свой комментарий',
    description:
      'Править может **только автор** — администратор чужой комментарий не редактирует ' +
      'и получает 403 (US-72). Срок правки не ограничен. После сохранения проставляется ' +
      '`editedAt`, и в ленте появляется пометка «изменён».\n\n' +
      'Уведомление создаётся только **вновь** упомянутым: ранее упомянутые повторно ' +
      'не уведомляются, нового уведомления о комментарии правка не создаёт (US-74, US-102).',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiParam({ name: 'commentId', format: 'uuid' })
  @ApiOkResponse({ type: CommentDto })
  @ApiBadRequestResponse({
    description: 'Пустой или слишком длинный текст (`invalid_comment_body`)',
  })
  @ApiForbiddenResponse({ description: 'Комментарий чужой (`comment_forbidden`)' })
  async update(
    @Param('key') key: string,
    @Param('commentId', new ParseUUIDPipe()) commentId: string,
    @Body() body: UpdateCommentDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<CommentDto> {
    const view = await this.comments.update(key, commentId, body.body, actor);
    return CommentDto.from(view.comment, { role: view.context.role, actorId: actor.id });
  }

  @Delete(':commentId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Удалить комментарий',
    description:
      'Свой комментарий удаляет автор, чужой — только администратор проекта; участник ' +
      'чужой удалить не может (US-73).\n\n' +
      'Удаление физическое: текст не остаётся нигде, плашки «комментарий удалён» в ленте ' +
      'нет. В историю задачи попадает факт удаления — кто удалил и чей комментарий, ' +
      '**без текста** (US-91). Уведомления, которые на него ссылались, остаются ' +
      'в центре уведомлений, но теряют ссылку на комментарий (US-102). Новых уведомлений ' +
      'удаление не создаёт.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiParam({ name: 'commentId', format: 'uuid' })
  @ApiNoContentResponse({ description: 'Комментарий удалён' })
  @ApiForbiddenResponse({
    description: 'Комментарий чужой, а вы не администратор (`comment_forbidden`)',
  })
  async remove(
    @Param('key') key: string,
    @Param('commentId', new ParseUUIDPipe()) commentId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<void> {
    await this.comments.remove(key, commentId, actor);
  }
}
