import { statusCategoryEnum } from '../database/schema/index.js';

/**
 * Категории статусов. Список выводится из enum'а БД, а не переписывается рядом:
 * два места с одним и тем же перечислением рано или поздно разъезжаются.
 *
 * Сами статусы категориями **не исчерпываются** — они данные в таблице `statuses`
 * (ADR-0003). Категория — служебная классификация: продукт спрашивает «завершена ли
 * задача», а не «называется ли статус „Закрыт“».
 */
export const STATUS_CATEGORIES = statusCategoryEnum.enumValues;

export type StatusCategory = (typeof STATUS_CATEGORIES)[number];
