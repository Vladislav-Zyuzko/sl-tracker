import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран списка задач очереди (`docs/design/screens/queue-issues.md`).
class QueueIssuesScreen extends StatelessWidget {
  /// @nodoc
  const QueueIssuesScreen({required this.queueKey, super.key});

  /// Ключ очереди из адреса. Уникален глобально и неизменяем (D-06).
  final String queueKey;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: 'Задачи очереди',
    description:
        'Здесь будет виртуализированный список задач очереди '
        'с фильтрами и множественным выбором.',
    parameters: {'key': queueKey},
  );
}
