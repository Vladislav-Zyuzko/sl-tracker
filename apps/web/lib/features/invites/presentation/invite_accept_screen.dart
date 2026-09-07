import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран приёма приглашения (`docs/design/screens/invite-accept.md`).
///
/// Живёт вне оболочки: пользователь ещё не внутри приложения.
class InviteAcceptScreen extends StatelessWidget {
  /// @nodoc
  const InviteAcceptScreen({required this.token, super.key});

  /// Токен приглашения из адреса.
  final String token;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PlaceholderScreen(
      title: 'Приглашение в проект',
      description:
          'Здесь будет приём приглашения: название проекта, '
          'роль и кнопка принятия.',
      parameters: {'token': token},
    ),
  );
}
