import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  PayloadTooLargeException,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
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
import { ATTACHMENT_MAX_BYTES } from '../storage/index.js';
import { AttachmentsService, type UploadedFile } from './attachments.service.js';
import { AttachmentDto, AttachmentListDto, ListAttachmentsQueryDto } from './dto/attachment.dto.js';

/**
 * Вложения задачи (US-46). Файл лежит в MinIO, наружу отдаётся подписанной ссылкой
 * с TTL — публичного бакета у нас нет.
 *
 * Не-участник проекта получает 404 и на список, и на загрузку: о существовании
 * задачи он знать не должен (permissions.md, п. 5).
 */
@ApiTags('attachments')
@ApiCookieAuth()
@ApiBearerAuth('bearer')
@ApiUnauthorizedResponse({ description: 'Нет сессии или она погашена' })
@ApiNotFoundResponse({ description: 'Задачи нет или пользователь не участник проекта' })
@Controller('issues/:key/attachments')
export class AttachmentsController {
  constructor(private readonly attachments: AttachmentsService) {}

  @Get()
  @ApiOperation({
    summary: 'Вложения задачи',
    description:
      'Видны всем участникам проекта, включая читателя. Порядок — по времени ' +
      'добавления. У каждого вложения приходят подписанные ссылки на просмотр ' +
      'и на скачивание; они действуют 10 минут, поэтому кэшировать их надолго нельзя.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42', description: 'Ключ задачи, регистронезависим' })
  @ApiOkResponse({ type: AttachmentListDto })
  @ApiBadRequestResponse({ description: 'Некорректный курсор (`invalid_cursor`)' })
  async list(
    @Param('key') key: string,
    @Query() query: ListAttachmentsQueryDto,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<AttachmentListDto> {
    const page = await this.attachments.list(key, actor, {
      limit: query.limit,
      cursor: query.cursor,
    });

    return {
      items: page.items.map((view) => AttachmentDto.from(view)),
      nextCursor: page.nextCursor,
      total: page.total,
      canUpload: page.context.role !== 'reader',
    };
  }

  @Post()
  @ApiOperation({
    summary: 'Приложить файл',
    description:
      'Администратор и участник проекта; читатель — 403 (US-46). Один файл в поле ' +
      '`file`, **любой тип**, до 25 МБ (D-21). Несколько файлов загружаются несколькими ' +
      'запросами: так у каждого свой прогресс и своя ошибка, и один отклонённый файл ' +
      'не отменяет остальные.\n\n' +
      'Тип определяется по содержимому файла, а не по заголовку и не по расширению; ' +
      'имя объекта в хранилище генерирует сервер, исходное имя сохраняется только ' +
      'для показа и скачивания. Добавление попадает в историю задачи.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiCreatedResponse({ type: AttachmentDto })
  @ApiBadRequestResponse({
    description: 'Файла нет (`attachment_file_required`) или он пустой (`attachment_empty`)',
  })
  @ApiPayloadTooLargeResponse({ description: 'Файл больше 25 МБ (`attachment_too_large`)' })
  @ApiForbiddenResponse({ description: 'Читатель не прикладывает файлы (`attachment_forbidden`)' })
  async upload(
    @Param('key') key: string,
    @Req() request: FastifyRequest,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<AttachmentDto> {
    const file = await readSingleFile(request);
    return AttachmentDto.from(await this.attachments.upload(key, file, actor));
  }

  @Delete(':attachmentId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Удалить вложение',
    description:
      'Администратор проекта — любое вложение, участник — **только своё**, читатель — ' +
      'никакое (US-46). Удаление попадает в историю задачи; файл убирается из хранилища.',
  })
  @ApiParam({ name: 'key', example: 'DEV-42' })
  @ApiParam({ name: 'attachmentId', format: 'uuid' })
  @ApiNoContentResponse({ description: 'Вложение удалено' })
  @ApiForbiddenResponse({
    description: 'Вложение чужое, а вы не администратор (`attachment_forbidden`)',
  })
  async remove(
    @Param('key') key: string,
    @Param('attachmentId', new ParseUUIDPipe()) attachmentId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ): Promise<void> {
    await this.attachments.remove(key, attachmentId, actor);
  }
}

/**
 * Читает единственный файл из multipart-запроса.
 *
 * Предел размера задаётся здесь, на маршруте: у обложки проекта он другой (5 МБ),
 * и общий потолок в настройке приложения не должен решать за домен. Файл читается
 * в память целиком — 25 МБ это допускают, и хранилищу всё равно нужна длина.
 */
async function readSingleFile(request: FastifyRequest): Promise<UploadedFile> {
  if (!request.isMultipart()) {
    throw new BadRequestException({
      code: 'attachment_file_required',
      message: 'Ожидается multipart/form-data с полем file',
    });
  }

  const file = await request.file({ limits: { fileSize: ATTACHMENT_MAX_BYTES, files: 1 } });
  if (!file) {
    throw new BadRequestException({
      code: 'attachment_file_required',
      message: 'Файл не передан',
    });
  }

  try {
    const buffer = await file.toBuffer();
    return { buffer, fileName: file.filename, truncated: file.file.truncated };
  } catch {
    // Единственная ожидаемая здесь ошибка — превышение лимита размера потоком.
    throw new PayloadTooLargeException({
      code: 'attachment_too_large',
      message: 'Файл больше 25 МБ',
    });
  }
}
