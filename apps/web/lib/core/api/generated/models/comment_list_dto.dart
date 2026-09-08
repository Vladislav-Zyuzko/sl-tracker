// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'comment_dto.dart';

part 'comment_list_dto.freezed.dart';
part 'comment_list_dto.g.dart';

@Freezed()
abstract class CommentListDto with _$CommentListDto {
  const factory CommentListDto({
    /// В хронологическом порядке, **сначала старые** (US-70)
    required List<CommentDto> items,

    /// Курсор **более ранних** комментариев — тех, что выше по ленте («Показать более ранние»). Страница без курсора отдаёт последние комментарии задачи. `null` — более ранних нет.
    required String? nextCursor,

    /// Всего комментариев у задачи — счётчик на вкладке
    required num total,

    /// Может ли запросивший написать комментарий. `false` у читателя: поле ввода не показывается, а прямой вызов API вернёт 403 (US-71, D-29).
    required bool canComment,
  }) = _CommentListDto;

  factory CommentListDto.fromJson(Map<String, Object?> json) =>
      _$CommentListDtoFromJson(json);
}
