// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/access_denied_info_dto.dart';
import '../models/me_response_dto.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Начать вход через Яндекс ID.
  ///
  /// Генерирует одноразовый `state` (32 байта, TTL 10 минут в Redis) и редиректит на страницу согласия Яндекса. Открывается полным переходом браузера, а не XHR: ответ — 302 на внешний домен. Если вход не настроен на инстансе, редиректит на `/login?error=oauth_not_configured`.
  ///
  /// [invite] - Токен ссылки-приглашения. Действующее приглашение пускает в трекер в обход списка доступа (ADR-0006, п. 3).
  ///
  /// [next] - Куда вернуть после входа. Принимается только путь внутри приложения (`/issues/DEV-42`); внешние адреса игнорируются.
  @GET('/api/auth/yandex/start')
  Future<void> authControllerStart({
    @Query('invite') dynamic invite,
    @Query('next') dynamic next,
  });

  /// Колбэк Яндекс ID.
  ///
  /// Проверяет `state`, меняет `code` на токен, читает профиль, заводит пользователя и сессию. Всегда отвечает редиректом:.
  ///
  /// - успех — на сохранённый адрес назначения или `/projects`, с cookie `sl_session`;.
  /// - нет доступа — на `/access-denied?ticket=<тикет>`, **без** cookie: ни сессии, ни пользователя в базе не появляется (US-05). Адрес, под которым человек вошёл, экран получает обменом тикета — в адресной строке его нет;.
  /// - ошибка — на `/login?error=<код>`: `access_denied`, `unauthorized_client` (приложение не прошло модерацию), `invalid_state`, `provider_unavailable`, `oauth_not_configured`, `server_error`.
  ///
  /// Отсутствие параметра `state` — не возврат из браузера пользователя, а посторонний запрос: 400 без редиректа. Негодный или истёкший `state` — редирект на `/login?error=invalid_state`.
  ///
  /// [error] - Код ошибки от Яндекса.
  @GET('/api/auth/yandex/callback')
  Future<void> authControllerCallback({
    @Query('error') dynamic error,
    @Query('state') dynamic state,
    @Query('code') dynamic code,
  });

  /// Обменять тикет экрана отказа на адрес.
  ///
  /// Экран «Доступ к трекеру закрыт» показывает адрес, под которым человек вошёл. Тикет одноразовый и живёт 60 секунд: адрес не попадает ни в адресную строку, ни в логи. Повторный обмен — 404. Ничего, кроме собственного адреса обратившегося, тикет не раскрывает.
  ///
  /// [ticket] - Значение параметра `ticket` из адреса редиректа.
  @GET('/api/auth/access-denied/{ticket}')
  Future<AccessDeniedInfoDto> authControllerAccessDeniedInfo({
    @Path('ticket') required String ticket,
  });

  /// Выйти.
  ///
  /// Уничтожает сессию **на сервере** и очищает cookie. Отвечает 204 и тогда, когда сессии уже нет: экран отказа доступа зовёт выход, не зная, была ли сессия создана.
  @POST('/api/auth/logout')
  Future<void> authControllerLogout();

  /// Текущий пользователь.
  ///
  /// Профиль из Яндекс ID и права уровня инстанса. 401 означает «сессии нет или она завершена» — в том числе после отзыва доступа (US-09).
  @GET('/api/me')
  Future<MeResponseDto> meControllerMe();
}
