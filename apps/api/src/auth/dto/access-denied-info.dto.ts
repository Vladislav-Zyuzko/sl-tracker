import { ApiProperty } from '@nestjs/swagger';

/**
 * Всё, что экран «Доступ к трекеру закрыт» узнаёт от сервера, — адрес, под которым
 * человек только что вошёл. Ни состава трекера, ни его владельца, ни причины отказа
 * (нет в списке или приглашение просрочено) здесь нет и быть не должно
 * (design/screens/access-denied.md, нормативный список).
 */
export class AccessDeniedInfoDto {
  @ApiProperty({
    example: 'ivan@yandex.ru',
    description: 'Адрес аккаунта Яндекса, которым человек вошёл',
  })
  email!: string;
}
