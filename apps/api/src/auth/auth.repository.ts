import { Inject, Injectable } from '@nestjs/common';
import { and, eq, isNull, sql } from 'drizzle-orm';
import { DB, type Database } from '../database/index.js';
import { accessEntries, identities, invitations, users } from '../database/schema/index.js';
import type { AuthenticatedUser } from './auth.types.js';

/** Профиль, пришедший от провайдера, уже приведённый к нашему виду. */
export interface ProviderProfile {
  provider: string;
  externalId: string;
  displayName: string;
  /** Уже нормализован к нижнему регистру. */
  email: string;
  avatarUrl: string | null;
}

/**
 * SQL уровня входа. Ни одного знания об HTTP: сюда приходит профиль, отсюда уходит
 * пользователь.
 */
@Injectable()
export class AuthRepository {
  constructor(@Inject(DB) private readonly db: Database) {}

  /**
   * Заводит или обновляет пользователя и его идентичность **в одной транзакции**
   * (ADR-0002) и в ней же связывает запись списка доступа с пользователем.
   *
   * Поиск идёт по паре (провайдер, идентификатор у провайдера) и только по ней.
   * Склейка по совпадению email запрещена: чужой аккаунт с тем же адресом иначе
   * захватывается одним входом (ADR-0002, «Последствия»).
   *
   * Имя и аватар перезаписываются на каждом входе — US-01 требует, чтобы смена
   * аватара в Яндексе доезжала до трекера.
   */
  async completeLogin(profile: ProviderProfile): Promise<AuthenticatedUser> {
    return this.db.transaction(async (tx) => {
      const now = new Date();

      const [identity] = await tx
        .select({ userId: identities.userId })
        .from(identities)
        .where(
          and(
            eq(identities.provider, profile.provider),
            eq(identities.externalId, profile.externalId),
          ),
        )
        .limit(1);

      let userId: string;
      if (identity) {
        userId = identity.userId;
        await tx
          .update(users)
          .set({
            displayName: profile.displayName,
            email: profile.email,
            avatarUrl: profile.avatarUrl,
            lastLoginAt: now,
          })
          .where(eq(users.id, userId));
      } else {
        const [created] = await tx
          .insert(users)
          .values({
            displayName: profile.displayName,
            email: profile.email,
            avatarUrl: profile.avatarUrl,
            lastLoginAt: now,
          })
          .returning({ id: users.id });
        userId = created!.id;
        await tx.insert(identities).values({
          userId,
          provider: profile.provider,
          externalId: profile.externalId,
        });
      }

      // Запись списка доступа узнаёт, кем оказался её адрес: экран управления доступом
      // показывает имя и аватар вошедшего и отметку «ещё не входил» (US-07).
      // Записи у человека может и не быть — он мог войти по приглашению в обход списка.
      await tx
        .update(accessEntries)
        .set({ userId, firstLoginAt: sql`coalesce(${accessEntries.firstLoginAt}, ${now})` })
        .where(sql`lower(${accessEntries.email}) = ${profile.email}`);

      const [user] = await tx
        .select({
          id: users.id,
          displayName: users.displayName,
          email: users.email,
          avatarUrl: users.avatarUrl,
        })
        .from(users)
        .where(eq(users.id, userId))
        .limit(1);

      const [owner] = await tx
        .select({ id: accessEntries.id })
        .from(accessEntries)
        .where(
          and(
            eq(accessEntries.isInstanceOwner, true),
            sql`(${accessEntries.userId} = ${userId}::uuid
                 or lower(${accessEntries.email}) = ${profile.email})`,
          ),
        )
        .limit(1);

      return { ...user!, isInstanceOwner: owner !== undefined };
    });
  }

  /**
   * Пользователь для охраны запроса: профиль и признак владельца трекера одним запросом.
   * Признак читается на каждом запросе, а не берётся из сессии, — иначе снятие
   * признака доехало бы до человека только после перелогина (US-07).
   */
  async findAuthenticatedUser(userId: string): Promise<AuthenticatedUser | null> {
    const [row] = await this.db
      .select({
        id: users.id,
        displayName: users.displayName,
        email: users.email,
        avatarUrl: users.avatarUrl,
        // Имена таблиц в подзапросе написаны буквально и не подставляются через
        // ${...}: в сыром `sql` Drizzle рендерит колонку без имени таблицы, и
        // `lower(email) = lower(email)` внутри подзапроса означало бы «сравни столбец
        // сам с собой» — то есть «владелец каждый». Проверено тестом.
        isInstanceOwner: sql<boolean>`exists (
          select 1
          from access_entries ae
          where ae.is_instance_owner
            and (ae.user_id = users.id or lower(ae.email) = lower(users.email))
        )`,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    return row ?? null;
  }

  /**
   * Есть ли действующее приглашение с таким токеном.
   *
   * Нужно на входе: приглашение работает **в обход** списка доступа (ADR-0006, п. 3),
   * иначе пригласить нового человека было бы невозможно. Само вступление в проект —
   * отдельное действие отдельного модуля.
   */
  async hasUsableInvitation(token: string): Promise<boolean> {
    const [row] = await this.db
      .select({ id: invitations.id })
      .from(invitations)
      .where(
        and(
          eq(invitations.token, token),
          isNull(invitations.revokedAt),
          sql`${invitations.expiresAt} > now()`,
        ),
      )
      .limit(1);

    return row !== undefined;
  }
}
