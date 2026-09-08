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
  });

  /// @nodoc
  final String title;

  /// @nodoc
  final String description;

  /// @nodoc
  final SLBannerVariant variant;

  /// Технический код — для баг-репорта, не для чтения.
  final String? details;

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
    // Вход на этом сервере не настроен. Повтор не поможет, и это не сбой сети,
    // поэтому текст говорит про сервер, а не про соединение.
    // Спека дизайна такой строки не содержит — см. отчёт, вопрос к дизайнеру.
    'oauth_not_configured' => LoginNotice(
      title: 'Вход временно недоступен',
      description:
          'Вход через Яндекс ID на этом сервере не настроен. '
          'Напишите администратору.',
      variant: SLBannerVariant.warning,
      details: code,
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
