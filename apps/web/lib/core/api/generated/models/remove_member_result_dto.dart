// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'remove_member_result_dto.freezed.dart';
part 'remove_member_result_dto.g.dart';

@Freezed()
abstract class RemoveMemberResultDto with _$RemoveMemberResultDto {
  const factory RemoveMemberResultDto({
    /// Сколько задач осталось без исполнителя: у задач исключённого поле «Исполнитель» очищается, и на каждую пишется запись истории (D-31).
    required num unassignedIssues,
  }) = _RemoveMemberResultDto;

  factory RemoveMemberResultDto.fromJson(Map<String, Object?> json) =>
      _$RemoveMemberResultDtoFromJson(json);
}
