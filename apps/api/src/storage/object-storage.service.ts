import { randomUUID } from 'node:crypto';
import {
  CreateBucketCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  HeadBucketCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Inject, Injectable, Logger, type OnModuleInit } from '@nestjs/common';
import { ENV, type Env } from '../config/index.js';

/** Сколько живёт подписанная ссылка на файл. Хватает, чтобы страница отрисовалась. */
export const SIGNED_URL_TTL_SECONDS = 600;

export interface StoredObject {
  objectKey: string;
  contentType: string;
  sizeBytes: number;
}

/**
 * Работа с MinIO по S3 API (CLAUDE.md, п. 2): SDK, а не самодельные подписанные запросы.
 *
 * Бакет **не публичный**. Наружу файл отдаётся только подписанной ссылкой с TTL,
 * которую выдаёт эндпоинт, уже проверивший права на объект. Прямая ссылка на объект
 * без подписи возвращает от MinIO отказ — это проверяется e2e-тестом обложки.
 *
 * Имя объекта генерирует сервер и никогда не берёт из имени загруженного файла:
 * пользовательское имя — это чужой ввод в пути, то есть заявка на обход каталога.
 */
@Injectable()
export class ObjectStorageService implements OnModuleInit {
  private readonly logger = new Logger(ObjectStorageService.name);
  private readonly bucket: string;
  /** Клиент для операций: ходит во внутренний адрес хранилища. */
  private readonly client: S3Client;
  /**
   * Клиент для подписи ссылок. Подпись привязана к хосту, поэтому ссылка должна
   * подписываться тем адресом, по которому к хранилищу пойдёт браузер.
   */
  private readonly signer: S3Client;
  /** Адрес, которым подписываются ссылки: он же попадает в браузер пользователя. */
  private readonly signerEndpoint: string;
  private bucketReady = false;

  constructor(@Inject(ENV) env: Env) {
    this.bucket = env.MINIO_BUCKET;

    const scheme = env.MINIO_USE_SSL ? 'https' : 'http';
    const internalEndpoint = `${scheme}://${env.MINIO_HOST}:${env.MINIO_PORT}`;
    const credentials = {
      accessKeyId: env.MINIO_ROOT_USER,
      secretAccessKey: env.MINIO_ROOT_PASSWORD,
    };

    this.client = new S3Client({
      endpoint: internalEndpoint,
      region: env.MINIO_REGION,
      credentials,
      // MinIO адресует бакет путём, а не поддоменом: без этого SDK пойдёт
      // на `sl-attachments.localhost`, которого не существует.
      forcePathStyle: true,
    });

    this.signerEndpoint = (env.MINIO_PUBLIC_URL ?? internalEndpoint).replace(/\/$/, '');
    this.signer =
      this.signerEndpoint === internalEndpoint
        ? this.client
        : new S3Client({
            endpoint: this.signerEndpoint,
            region: env.MINIO_REGION,
            credentials,
            forcePathStyle: true,
          });
  }

  async onModuleInit(): Promise<void> {
    // Недоступное хранилище на старте не роняет API: загрузка обложек — не путь входа,
    // а состояние зависимостей показывает /api/health.
    await this.ensureBucket().catch((error: unknown) => {
      this.logger.warn(`Бакет ${this.bucket} не подготовлен: ${describe(error)}`);
    });
  }

  /** Имя объекта строится сервером из идентификаторов, а не из имени файла. */
  buildObjectKey(prefix: string, extension: string): string {
    return `${prefix}/${randomUUID()}.${extension}`;
  }

  async put(objectKey: string, body: Buffer, contentType: string): Promise<StoredObject> {
    await this.ensureBucket();
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: objectKey,
        Body: body,
        ContentType: contentType,
        ContentLength: body.byteLength,
      }),
    );

    return { objectKey, contentType, sizeBytes: body.byteLength };
  }

  /** Удаление идемпотентно: отсутствующий объект — не ошибка вызывающего кода. */
  async remove(objectKey: string): Promise<void> {
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: objectKey }));
  }

  async signedUrl(objectKey: string, ttlSeconds = SIGNED_URL_TTL_SECONDS): Promise<string> {
    return getSignedUrl(
      this.signer,
      new GetObjectCommand({ Bucket: this.bucket, Key: objectKey }),
      {
        expiresIn: ttlSeconds,
      },
    );
  }

  /** Полный адрес объекта без подписи — нужен тесту, который проверяет отказ MinIO. */
  publicObjectUrl(objectKey: string): string {
    return `${this.signerEndpoint}/${this.bucket}/${objectKey}`;
  }

  private async ensureBucket(): Promise<void> {
    if (this.bucketReady) {
      return;
    }

    try {
      await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch {
      // Бакета нет (или к нему нет доступа) — пробуем создать; гонку двух процессов
      // гасит сам MinIO, повторное создание уже существующего бакета не ошибка.
      await this.client
        .send(new CreateBucketCommand({ Bucket: this.bucket }))
        .catch((error: unknown) => {
          this.logger.warn(`Не удалось создать бакет ${this.bucket}: ${describe(error)}`);
        });
    }

    this.bucketReady = true;
  }
}

function describe(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
