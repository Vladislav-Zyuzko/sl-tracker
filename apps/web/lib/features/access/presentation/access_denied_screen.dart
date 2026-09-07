import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';

/// Экран «Доступ к трекеру закрыт» (`docs/design/screens/access-denied.md`).
///
/// Вне оболочки: пользователь не внутри приложения. Кнопки действия нет —
/// сделать отсюда он ничего не может, и предлагать ему кнопку нечестно.
///
/// Email показывается **не из адреса**, а обменом одноразового тикета
/// на `GET /api/auth/access-denied/{ticket}`; тикет живёт 60 секунд.
/// Поэтому [ticket] принимается уже сейчас, а сам обмен подключается вместе
/// с остальными вызовами API: пока тикета нет или он просрочен, экран обязан
/// работать и без email — текст ниже от него не зависит.
class AccessDeniedScreen extends StatelessWidget {
  /// @nodoc
  const AccessDeniedScreen({this.ticket, super.key});

  /// Одноразовый тикет из адреса. `null` — пользователь пришёл на экран
  /// напрямую, без редиректа от бэкенда.
  final String? ticket;

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SLEmptyState(
      icon: Icons.lock_outline_rounded,
      title: 'Доступ к трекеру закрыт',
      description:
          'Вашей учётной записи нет в списке доступа. '
          'Попросите владельца трекера добавить вас.',
    ),
  );
}
