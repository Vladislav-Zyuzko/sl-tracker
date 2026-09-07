import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран списка доступа к трекеру (`docs/design/screens/access-list.md`).
///
/// Виден только владельцу трекера. Обычный участник о существовании экрана
/// не узнаёт: пункт меню ему не показывается, а сервер откажет независимо
/// от интерфейса.
class AccessListScreen extends StatelessWidget {
  /// @nodoc
  const AccessListScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Доступ к трекеру',
    description:
        'Здесь будет список людей, допущенных в трекер, '
        'с возможностью выдать и отозвать доступ.',
  );
}
