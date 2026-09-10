import 'package:flutter/material.dart';

import 'package:sl_tracker_web/features/notifications/presentation/widgets/notification_row.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Скелетон ленты уведомлений (`docs/design/screens/notifications.md`).
///
/// Повторяет геометрию строки: та же высота, та же колонка аватара, те же
/// две полоски текста. Иначе при загрузке лента прыгает, а скелетон
/// обещает не то, что придёт.
class NotificationsSkeleton extends StatelessWidget {
  /// @nodoc
  const NotificationsSkeleton({this.compact = false, super.key});

  /// Раскладка телефона.
  final bool compact;

  /// Сколько строк показывает скелетон.
  static const rows = 8;

  @override
  Widget build(BuildContext context) => SLShimmeringEffect(
    child: Column(
      children: [
        for (var index = 0; index < rows; index++)
          SizedBox(
            height: compact
                ? NotificationRow.compactHeight
                : NotificationRow.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
              child: Row(
                children: [
                  const SizedBox(width: NotificationRow.dotColumn),
                  const SLSkeletonBox.circle(diameter: 20),
                  const SizedBox(width: SLSpacing.space2),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          child: const SLSkeletonLine(height: 14),
                        ),
                        const SizedBox(height: SLSpacing.space1),
                        FractionallySizedBox(
                          widthFactor: 0.45,
                          child: const SLSkeletonLine(height: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SLSpacing.space2),
                  const SLSkeletonLine(width: 40),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
