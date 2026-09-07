import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран профиля и настроек уведомлений (`docs/design/screens/profile.md`).
class ProfileScreen extends StatelessWidget {
  /// @nodoc
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Профиль',
    description:
        'Здесь будут данные пользователя и настройки '
        'уведомлений.',
  );
}
