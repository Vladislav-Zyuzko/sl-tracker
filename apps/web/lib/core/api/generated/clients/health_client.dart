// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/health_response_dto.dart';

part 'health_client.g.dart';

@RestApi()
abstract class HealthClient {
  factory HealthClient(Dio dio, {String? baseUrl}) = _HealthClient;

  /// Проверка доступности сервиса и его зависимостей.
  ///
  /// Отвечает 200, если доступны PostgreSQL и Redis, иначе 503. Авторизация не требуется: эндпоинт используется как health-проба обратного прокси.
  @GET('/api/health')
  Future<HealthResponseDto> healthControllerCheck();
}
