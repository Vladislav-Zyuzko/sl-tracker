import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран проекта (`docs/design/screens/project.md`).
class ProjectScreen extends StatelessWidget {
  /// @nodoc
  const ProjectScreen({required this.slug, super.key});

  /// Slug проекта из адреса. Не меняется при переименовании проекта,
  /// поэтому отправленные ссылки не ломаются (ADR-0005).
  final String slug;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: 'Проект',
    description: 'Здесь будут очереди проекта, участники и настройки.',
    parameters: {'slug': slug},
  );
}
