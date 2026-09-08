import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

/// Сообщение над кнопкой входа (`docs/design/screens/login.md`).
///
/// Экран не пересказывает пользователю технические коды: код уезжает
/// в [details] и виден только в раскрытом блоке «Подробности».
@immutable
class LoginNotice {
  /// @nodoc
  const LoginNotice({
    required this.title,
    required this.description,
    required this.variant,
    this.details,
    this.blocksSignIn = false,
  });

  /// @nodoc
  final String title;

  /// @nodoc
  final String description;

  /// @nodoc
  final SLBannerVariant variant;

  /// Технический код — для баг-репорта, не для чтения.
  final String? details;

  /// Отключать ли кнопку входа.
  ///
  /// Верно ровно для одного кода — `oauth_not_configured`: ненастроенный
  /// OAuth сам не рассосётся, и повтор гарантированно бессмыслен
  /// (`screens/login.md`). У остальных кодов кнопка остаётся активной:
  /// отключать её там значило бы решать за человека, что пробовать
  /// не стоит.
  final bool blocksSignIn;

  /// Сообщение по коду ошибки OAuth из адреса (`/login?error=<код>`).
  ///
  /// Коды перечислены в контракте (`/api/auth/yandex/callback`). Неизвестный
  /// код — это не повод показать пустой экран: он попадает в общую ветку.
  factory LoginNotice.ofOAuthError(String code) => switch (code) {
    // Человек не подтвердил доступ на стороне Яндекса. Это не поломка,
    // поэтому спокойный тон и `info`.
    'access_denied' => LoginNotice(
      title: 'Вход отменён',
      description:
          'Вы не подтвердили доступ. '
          'Нажмите «Войти через Яндекс» ещё раз.',
      variant: SLBannerVariant.info,
      details: code,
    ),
    // Штатное состояние на старте проекта, пока OAuth-приложение проходит
    // модерацию (CLAUDE.md, решение 7). Пользователь должен понять,
    // что дело не в нём, — отсюда `warning`, а не `danger`.
    'unauthorized_client' => LoginNotice(
      title: 'Вход временно недоступен',
      description:
          'Приложение ещё проверяется на стороне Яндекса. '
          'Попробуйте позже или напишите администратору.',
      variant: SLBannerVariant.warning,
      details: code,
    ),
    'invalid_state' => LoginNotice(
      title: 'Не удалось завершить вход',
      description: 'Страница входа устарела. Начните заново.',
      variant: SLBannerVariant.danger,
      details: code,
    ),
    // Вход на этом сервере не настроен. Слово «временно» здесь было бы
    // неправдой: ненастроенный OAuth сам не рассосётся, а этой же фразой
    // подписан `unauthorized_client`, где ожидание как раз помогает.
    // Тип `warning`, а не `danger`: человек ничего не сломал, это
    // незаконченная настройка.
    'oauth_not_configured' => LoginNotice(
      title: 'Вход не настроен',
      description:
          'На этом сервере не настроен вход через Яндекс ID. '
          'Это чинится администратором, повторять попытку бесполезно.',
      variant: SLBannerVariant.warning,
      details: code,
      blocksSignIn: true,
    ),
    'provider_unavailable' || 'server_error' => LoginNotice(
      title: 'Не удалось войти',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      variant: SLBannerVariant.danger,
      details: code,
    ),
    _ => LoginNotice(
      title: 'Не удалось войти',
      description: 'Что-то пошло не так. Попробуйте ещё раз.',
      variant: SLBannerVariant.danger,
      details: code,
    ),
  };

  /// Сообщение по сбою проверки сессии.
  ///
  /// Сюда попадают сеть, таймаут и 5xx: «сессии нет» через 401 сообщения
  /// не порождает — это обычный вход.
  static LoginNotice? ofFailure(ApiFailure? failure) {
    if (failure == null || failure.kind == ApiFailureKind.unauthorized) {
      return null;
    }

    final details = [
      failure.kind.name,
      if (failure.statusCode != null) 'HTTP ${failure.statusCode}',
      if (failure.code != null) failure.code!,
      if (failure.requestId != null) 'request-id: ${failure.requestId}',
    ].join(', ');

    return LoginNotice(
      title: 'Не удалось войти',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      variant: SLBannerVariant.danger,
      details: details,
    );
  }

  /// Сессия была и истекла (US-02).
  static const sessionExpired = LoginNotice(
    title: 'Сессия истекла',
    description: 'Войдите снова, чтобы продолжить работу.',
    variant: SLBannerVariant.info,
  );
}
