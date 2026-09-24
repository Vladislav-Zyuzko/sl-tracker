// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'token_dto_purpose.dart';

part 'token_dto.freezed.dart';
part 'token_dto.g.dart';

@Freezed()
abstract class TokenDto with _$TokenDto {
  const factory TokenDto({
    required String id,

    /// Имя, которое дал владелец
    required String name,

    /// Первые 8 символов токена — чтобы опознать его в списке. Не секрет и не часть проверки: сам секрет не хранится нигде и после выпуска не показывается.
    required String prefix,

    /// Всегда `pat`: сессии входа через этот раздел не видны и не отзываются.
    required TokenDtoPurpose purpose,
    required DateTime createdAt,

    /// Когда токен предъявляли в последний раз, с точностью до суток: чаще раза в день отметка не обновляется. Пока токеном ни разу не пользовались, **не позже** `createdAt` — отметка ставится кодом, а `createdAt` дефолтом базы, и они расходятся на единицы миллисекунд. Признак «ни разу» проверяется как `lastSeenAt <= createdAt`, сравнение на равенство даст ложное «уже пользовались».
    required DateTime lastSeenAt,

    /// Когда токен перестанет действовать. Срок задаётся при выпуске и **не продлевается** использованием; бессрочных токенов не бывает.
    required DateTime expiresAt,

    /// Когда токен отозвали. `null` — токен не отозван.
    required DateTime? revokedAt,
  }) = _TokenDto;

  factory TokenDto.fromJson(Map<String, Object?> json) =>
      _$TokenDtoFromJson(json);
}
