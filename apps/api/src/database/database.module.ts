import { Global, Inject, Module, type OnApplicationShutdown } from '@nestjs/common';
import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';

const { Pool } = pg;
import { ENV, type Env } from '../config/index.js';
import { DB, PG_POOL } from './database.tokens.js';
import * as schema from './schema/index.js';

@Global()
@Module({
  providers: [
    {
      provide: PG_POOL,
      inject: [ENV],
      useFactory: (env: Env) =>
        new Pool({
          host: env.POSTGRES_HOST,
          port: env.POSTGRES_PORT,
          user: env.POSTGRES_USER,
          password: env.POSTGRES_PASSWORD,
          database: env.POSTGRES_DB,
          // Пул небольшой намеренно: нагрузка на трекер малой команды невелика,
          // а каждое соединение к PostgreSQL стоит памяти на сервере БД.
          max: 10,
          idleTimeoutMillis: 30_000,
          connectionTimeoutMillis: 5_000,
        }),
    },
    {
      provide: DB,
      inject: [PG_POOL],
      useFactory: (pool: pg.Pool) => drizzle(pool, { schema, casing: 'snake_case' }),
    },
  ],
  exports: [DB, PG_POOL],
})
export class DatabaseModule implements OnApplicationShutdown {
  constructor(@Inject(PG_POOL) private readonly pool: pg.Pool) {}

  async onApplicationShutdown(): Promise<void> {
    await this.pool.end();
  }
}
