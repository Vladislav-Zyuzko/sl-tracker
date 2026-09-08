import { Module } from '@nestjs/common';
import { MentionsRepository } from './mentions.repository.js';

/**
 * Упоминания (US-74). Модуль намеренно не зависит ни от задач, ни от комментариев:
 * упоминание живёт и в тексте комментария, и в описании задачи, и обе стороны
 * должны уметь им пользоваться, не образуя цикла импортов.
 */
@Module({
  providers: [MentionsRepository],
  exports: [MentionsRepository],
})
export class MentionsModule {}
