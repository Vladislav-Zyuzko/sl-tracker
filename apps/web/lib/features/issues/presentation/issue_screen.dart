import 'package:flutter/material.dart';

import 'package:sl_tracker_web/app/placeholder_screen.dart';

/// Экран задачи (`docs/design/screens/issue.md`).
class IssueScreen extends StatelessWidget {
  /// @nodoc
  const IssueScreen({required this.issueKey, super.key});

  /// Ключ задачи вида `DEV-42`. Публичный идентификатор: ссылка на задачу
  /// стабильна и человекочитаема (ADR-0004, ADR-0005).
  final String issueKey;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
    title: issueKey,
    description:
        'Здесь будут тема, описание, комментарии, история '
        'изменений и вложения задачи.',
    parameters: {'key': issueKey},
  );
}
