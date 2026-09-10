import 'package:flutter/material.dart';

import 'package:sl_tracker_web/features/profile/presentation/widgets/notification_setting_row.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_switch.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Скелетон блока «кто я» (`docs/design/screens/profile.md`).
class ProfileIdentitySkeleton extends StatelessWidget {
  /// @nodoc
  const ProfileIdentitySkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SLShimmeringEffect(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SLSkeletonBox.circle(diameter: 48),
        SizedBox(width: SLSpacing.space4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SLSkeletonLine(width: 200, height: 20),
            SizedBox(height: SLSpacing.space2),
            SLSkeletonLine(width: 240, height: 14),
          ],
        ),
      ],
    ),
  );
}

/// Скелетон списка настроек: шесть строк по 48.
class ProfileSettingsSkeleton extends StatelessWidget {
  /// @nodoc
  const ProfileSettingsSkeleton({super.key});

  /// Столько же строк, сколько типов уведомлений: список фиксирован.
  static const rows = 6;

  @override
  Widget build(BuildContext context) => SLShimmeringEffect(
    child: Column(
      children: [
        for (var index = 0; index < rows; index++)
          SizedBox(
            height: NotificationSettingRow.minHeight,
            child: Row(
              children: [
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: const SLSkeletonLine(height: 14),
                  ),
                ),
                const SizedBox(width: SLSpacing.space3),
                const SLSkeletonBox(
                  width: SLSwitch.width,
                  height: SLSwitch.height,
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
