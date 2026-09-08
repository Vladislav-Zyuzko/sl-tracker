import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';

/// Вкладка «Очереди» (`docs/design/screens/project.md`).
///
/// **Заглушка.** Списка очередей в контракте API пока нет: эндпоинт
/// `GET /api/projects/{slug}/queues` бэкенд делает параллельно. Показывать
/// здесь «Очередей пока нет» нельзя — мы этого не спрашивали и не знаем;
/// вместо этого экран честно говорит, чего ждёт.
///
/// Когда эндпоинт появится, сюда встают строки очередей (ключ, название,
/// число незавершённых задач), состояния загрузки, ошибки и пустоты
/// из спеки и кнопка «Создать очередь» для администратора.
class ProjectQueuesTab extends StatelessWidget {
  /// @nodoc
  const ProjectQueuesTab({required this.canManage, super.key});

  /// Администратор ли текущий пользователь. Пока влияет только на текст:
  /// участнику и читателю просить создавать очередь бессмысленно.
  final bool canManage;

  @override
  Widget build(BuildContext context) => SLEmptyState(
    icon: Icons.inbox_outlined,
    title: 'Очереди появятся здесь',
    description: canManage
        ? 'Очередь — это поток задач: её ключ станет началом ключей '
              'её задач, DEV-1, DEV-2. Раздел ждёт эндпоинта списка очередей '
              'в контракте API.'
        : 'Раздел ждёт эндпоинта списка очередей в контракте API.',
  );
}
