import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран «Мои проекты» (`docs/design/screens/projects.md`).
class ProjectsScreen extends StatelessWidget {
  /// @nodoc
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Мои проекты',
    description:
        'Здесь будет список проектов, к которым у вас есть '
        'доступ, с очередями и счётчиками задач. Экран ждёт эндпоинта '
        'списка проектов в контракте API.',
  );
}
