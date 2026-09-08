// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'access_entry_dto.dart';

part 'access_entry_list_dto.freezed.dart';
part 'access_entry_list_dto.g.dart';

@Freezed()
abstract class AccessEntryListDto with _$AccessEntryListDto {
  const factory AccessEntryListDto({
    /// Сначала новые
    required List<AccessEntryDto> items,

    /// Курсор следующей страницы. `null` — записей больше нет.
    required String? nextCursor,

    /// Всего записей с учётом поиска
    required num total,
  }) = _AccessEntryListDto;

  factory AccessEntryListDto.fromJson(Map<String, Object?> json) =>
      _$AccessEntryListDtoFromJson(json);
}
