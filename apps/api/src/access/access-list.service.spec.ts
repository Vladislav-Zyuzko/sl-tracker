import { randomUUID } from 'node:crypto';
import { beforeEach, describe, expect, it } from '@jest/globals';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import type { RealtimePublisher } from '../realtime/realtime.publisher.js';
import type { SessionService } from '../sessions/index.js';
import type { AuthenticatedUser } from '../auth/auth.types.js';
import type {
  AccessEntryRow,
  AccessListRepository,
  ListOptions,
} from './access-list.repository.js';
import { AccessListService, decodeCursor, encodeCursor } from './access-list.service.js';

/**
 * Инварианты списка доступа (permissions.md, п. 1.2 и п. 5). Это единственное место,
 * где они проверяются: скрытый пункт меню на клиенте защитой не является.
 */

const OWNER: AuthenticatedUser = {
  id: 'owner-1',
  displayName: 'Анна',
  email: 'Anna@Example.com',
  avatarUrl: null,
  isInstanceOwner: true,
};

function entry(overrides: Partial<AccessEntryRow> = {}): AccessEntryRow {
  return {
    id: randomUUID(),
    email: 'ivan@yandex.ru',
    source: 'manual',
    isInstanceOwner: false,
    createdAt: new Date('2026-03-14T10:00:00.000Z'),
    firstLoginAt: null,
    userId: null,
    userDisplayName: null,
    userAvatarUrl: null,
    addedByUserId: null,
    addedByDisplayName: null,
    ...overrides,
  };
}

class FakeRepository {
  rows: AccessEntryRow[] = [];
  readonly inserted: { email: string; addedByUserId: string }[] = [];
  conflictOnInsert = false;

  list(options: ListOptions): Promise<AccessEntryRow[]> {
    return Promise.resolve(this.rows.slice(0, options.limit));
  }

  count(): Promise<number> {
    return Promise.resolve(this.rows.length);
  }

  findById(id: string): Promise<AccessEntryRow | null> {
    return Promise.resolve(this.rows.find((row) => row.id === id) ?? null);
  }

  existsByEmail(email: string): Promise<boolean> {
    return Promise.resolve(this.rows.some((row) => row.email === email));
  }

  insertManual(email: string, addedByUserId: string): Promise<AccessEntryRow | null> {
    this.inserted.push({ email, addedByUserId });
    if (this.conflictOnInsert) {
      return Promise.resolve(null);
    }
    const row = entry({ email, addedByUserId, source: 'manual' });
    this.rows.push(row);
    return Promise.resolve(row);
  }

  delete(id: string): Promise<boolean> {
    const before = this.rows.length;
    this.rows = this.rows.filter((row) => row.id !== id);
    return Promise.resolve(this.rows.length < before);
  }

  setInstanceOwner(id: string, value: boolean): Promise<AccessEntryRow | null> {
    const row = this.rows.find((item) => item.id === id);
    if (!row) {
      return Promise.resolve(null);
    }
    row.isInstanceOwner = value;
    return Promise.resolve(row);
  }

  countOwners(): Promise<number> {
    return Promise.resolve(this.rows.filter((row) => row.isInstanceOwner).length);
  }

  findUserIdsForEntry(row: AccessEntryRow): Promise<string[]> {
    return Promise.resolve(row.userId ? [row.userId] : []);
  }
}

class FakeSessions {
  readonly revokedFor: string[] = [];
  sessionsPerUser = 2;

  destroyAllForUser(userId: string): Promise<number> {
    this.revokedFor.push(userId);
    return Promise.resolve(this.sessionsPerUser);
  }
}

/** Отзыв доступа обязан закрыть и уже открытые сокеты, а не только сессии (US-09). */
class FakeRealtime {
  readonly closedFor: string[] = [];

  revokeUser(userId: string): Promise<void> {
    this.closedFor.push(userId);
    return Promise.resolve();
  }
}

describe('AccessListService', () => {
  let repository: FakeRepository;
  let sessions: FakeSessions;
  let realtime: FakeRealtime;
  let service: AccessListService;

  beforeEach(() => {
    repository = new FakeRepository();
    sessions = new FakeSessions();
    realtime = new FakeRealtime();
    service = new AccessListService(
      repository as unknown as AccessListRepository,
      sessions as unknown as SessionService,
      realtime as unknown as RealtimePublisher,
    );
  });

  describe('добавление', () => {
    it('нормализует адрес к нижнему регистру', async () => {
      await service.add('  Ivan@Yandex.RU  ', OWNER);
      expect(repository.inserted).toEqual([{ email: 'ivan@yandex.ru', addedByUserId: 'owner-1' }]);
    });

    it('источник добавленной вручную записи — manual, владельцем она не становится', async () => {
      const created = await service.add('ivan@yandex.ru', OWNER);
      expect(created.source).toBe('manual');
      expect(created.isInstanceOwner).toBe(false);
    });

    it('повторный адрес — 409', async () => {
      repository.conflictOnInsert = true;
      await expect(service.add('ivan@yandex.ru', OWNER)).rejects.toBeInstanceOf(ConflictException);
    });

    it('некорректный адрес — 400, до базы не доходит', async () => {
      await expect(service.add('не-адрес', OWNER)).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.inserted).toHaveLength(0);
    });
  });

  describe('отзыв доступа', () => {
    it('гасит все сессии человека', async () => {
      const row = entry({ userId: 'user-9' });
      repository.rows = [row, entry({ email: 'anna@example.com', isInstanceOwner: true })];

      const result = await service.remove(row.id, OWNER);

      expect(result.revokedSessions).toBe(2);
      expect(sessions.revokedFor).toEqual(['user-9']);
      expect(repository.rows).toHaveLength(1);
    });

    it('закрывает и открытые WebSocket: погашенная сессия сама сокет не роняет', async () => {
      const row = entry({ userId: 'user-9' });
      repository.rows = [row, entry({ email: 'anna@example.com', isInstanceOwner: true })];

      await service.remove(row.id, OWNER);

      expect(realtime.closedFor).toEqual(['user-9']);
    });

    it('свою запись удалить нельзя — 409, даже если регистр адреса другой', async () => {
      const own = entry({ email: 'anna@example.com' });
      repository.rows = [own];

      await expect(service.remove(own.id, OWNER)).rejects.toBeInstanceOf(ConflictException);
      expect(repository.rows).toHaveLength(1);
      expect(sessions.revokedFor).toHaveLength(0);
      expect(realtime.closedFor).toHaveLength(0);
    });

    it('свою запись, связанную по пользователю, тоже удалить нельзя', async () => {
      const own = entry({ email: 'другой@example.com', userId: OWNER.id });
      repository.rows = [own];
      await expect(service.remove(own.id, OWNER)).rejects.toBeInstanceOf(ConflictException);
    });

    it('запись последнего владельца удалить нельзя — 409', async () => {
      const lastOwner = entry({ email: 'petr@example.com', isInstanceOwner: true });
      repository.rows = [lastOwner];

      await expect(service.remove(lastOwner.id, OWNER)).rejects.toBeInstanceOf(ConflictException);
      expect(repository.rows).toHaveLength(1);
    });

    it('несуществующая запись — 404', async () => {
      await expect(service.remove(randomUUID(), OWNER)).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('признак владельца', () => {
    it('выдаётся', async () => {
      const row = entry();
      repository.rows = [row];

      const updated = await service.setInstanceOwner(row.id, true);

      expect(updated.isInstanceOwner).toBe(true);
    });

    it('снимается, пока владелец не последний', async () => {
      const first = entry({ isInstanceOwner: true });
      const second = entry({ email: 'petr@example.com', isInstanceOwner: true });
      repository.rows = [first, second];

      const updated = await service.setInstanceOwner(first.id, false);

      expect(updated.isInstanceOwner).toBe(false);
    });

    it('с последнего владельца не снимается — 409', async () => {
      const only = entry({ isInstanceOwner: true });
      repository.rows = [only];

      await expect(service.setInstanceOwner(only.id, false)).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(only.isInstanceOwner).toBe(true);
    });
  });

  describe('страница списка', () => {
    it('отдаёт курсор, когда записей больше страницы', async () => {
      repository.rows = Array.from({ length: 5 }, (_, index) =>
        entry({ email: `user${index}@example.com` }),
      );

      const page = await service.list({ limit: 2 });

      expect(page.items).toHaveLength(2);
      expect(page.nextCursor).not.toBeNull();
      expect(page.total).toBe(5);
    });

    it('курсор последней страницы пуст', async () => {
      repository.rows = [entry()];
      const page = await service.list({ limit: 50 });
      expect(page.nextCursor).toBeNull();
    });

    it('битый курсор — 400', async () => {
      await expect(service.list({ cursor: 'не-курсор' })).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('лимит ограничен сверху даже при попытке запросить всё', async () => {
      repository.rows = Array.from({ length: 200 }, () => entry());
      const page = await service.list({ limit: 100_000 });
      expect(page.items.length).toBeLessThanOrEqual(100);
    });
  });

  describe('курсор', () => {
    it('переживает кодирование и разбор', () => {
      const createdAt = new Date('2026-03-14T10:00:00.000Z');
      const id = randomUUID();
      expect(decodeCursor(encodeCursor(createdAt, id))).toEqual({ createdAt, id });
    });
  });
});
