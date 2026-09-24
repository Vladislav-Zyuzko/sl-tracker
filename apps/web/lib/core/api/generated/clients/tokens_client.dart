// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_token_dto.dart';
import '../models/issued_token_dto.dart';
import '../models/token_list_dto.dart';

part 'tokens_client.g.dart';

@RestApi()
abstract class TokensClient {
  factory TokensClient(Dio dio, {String? baseUrl}) = _TokensClient;

  /// Мои токены доступа.
  ///
  /// Сначала новые. Секрета в ответе нет ни при каких условиях — в базе его и не существует, хранится только HMAC. Сессии входа в список не попадают.
  ///
  /// [includeRevoked] - Показать отозванные токены. По умолчанию их в списке нет.
  @GET('/api/tokens')
  Future<TokenListDto> tokensControllerList({
    @Query('includeRevoked') bool? includeRevoked = false,
  });

  /// Выпустить токен доступа.
  ///
  /// Токен выпускается **текущему пользователю** и даёт ровно его права: отдельной машинной идентичности в трекере нет, задачи и комментарии подписываются владельцем токена (RFC MCP, §5.2).
  ///
  /// **Секрет возвращается единственный раз** — в этом ответе. Повторно получить его нельзя: в базе лежит только HMAC. Потерян — выпускайте новый и отзывайте старый.
  ///
  /// Срок обязателен и конечен: по умолчанию 365 дней, допустимо 1..3650. Использование токена срок **не продлевает**.
  @POST('/api/tokens')
  Future<IssuedTokenDto> tokensControllerCreate({
    @Body() required CreateTokenDto body,
  });

  /// Отозвать токен.
  ///
  /// Действует немедленно: следующий запрос с этим токеном получает 401 `session_expired`. Идемпотентно — повторный отзыв своего токена тоже 204.
  ///
  /// Чужой, несуществующий и не-PAT идентификатор отвечают одинаково (404): существование чужого токена раскрывать нельзя.
  ///
  /// [id] - Идентификатор токена из списка.
  @DELETE('/api/tokens/{id}')
  Future<void> tokensControllerRevoke({@Path('id') required String id});
}
