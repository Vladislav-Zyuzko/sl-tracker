import {
  type ArgumentsHost,
  Catch,
  type ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { FastifyReply, FastifyRequest } from 'fastify';

interface ErrorBody {
  statusCode: number;
  message: string;
  error?: string;
  /** Машиночитаемая причина, если её задал доменный код. */
  code?: string;
}

/**
 * Единый формат ошибки наружу.
 *
 * Наружу не уходят ни стектрейсы, ни тексты ошибок драйвера БД: сообщение вида
 * `duplicate key value violates unique constraint "issues_key_key"` рассказывает
 * о схеме больше, чем следует. Всё непредвиденное превращается в 500 с общим текстом,
 * подробности — в лог сервера.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const reply = ctx.getResponse<FastifyReply>();
    const request = ctx.getRequest<FastifyRequest>();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const response = exception.getResponse();
      const body: ErrorBody =
        typeof response === 'string'
          ? { statusCode: status, message: response }
          : {
              message: exception.message,
              ...(response as Record<string, unknown>),
              statusCode: status,
            };

      if (status >= 500) {
        this.logger.error(`${request.method} ${request.url}`, exception.stack);
      }

      void reply.status(status).send(body);
      return;
    }

    this.logger.error(
      `Необработанная ошибка: ${request.method} ${request.url}`,
      exception instanceof Error ? exception.stack : String(exception),
    );

    void reply.status(HttpStatus.INTERNAL_SERVER_ERROR).send({
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      message: 'Внутренняя ошибка сервера',
    } satisfies ErrorBody);
  }
}
