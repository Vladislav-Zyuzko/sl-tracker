// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'access_denied_info_dto.freezed.dart';
part 'access_denied_info_dto.g.dart';

@Freezed()
abstract class AccessDeniedInfoDto with _$AccessDeniedInfoDto {
  const factory AccessDeniedInfoDto({
    /// Адрес аккаунта Яндекса, которым человек вошёл
    required String email,
  }) = _AccessDeniedInfoDto;

  factory AccessDeniedInfoDto.fromJson(Map<String, Object?> json) =>
      _$AccessDeniedInfoDtoFromJson(json);
}
