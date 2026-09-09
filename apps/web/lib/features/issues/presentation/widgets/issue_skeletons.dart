import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

/// Скелетоны экрана задачи (`docs/design/screens/issue.md`, «Состояния»).
///
/// Скелетон, а не спиннер по центру: раскладка экрана известна заранее,
/// и показывать её каркас честнее, чем крутить колесо на пустом месте.
/// Крошки и ключ задачи скелетоном **не** закрываются — они есть в адресе
/// и появляются сразу.
class IssueHeaderSkeleton extends StatelessWidget {
  /// @nodoc
  const IssueHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SLShimmeringEffect(
    child: Padding(
      padding: EdgeInsets.only(top: SLSpacing.space2),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.6,
        child: SLSkeletonLine(height: 20),
      ),
    ),
  );
}

/// Три полоски описания: 100 / 100 / 60 %.
class DescriptionSkeleton extends StatelessWidget {
  /// @nodoc
  const DescriptionSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SLShimmeringEffect(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SLSkeletonLine(height: 14),
        SizedBox(height: SLSpacing.space2),
        SLSkeletonLine(height: 14),
        SizedBox(height: SLSpacing.space2),
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.6,
          child: SLSkeletonLine(height: 14),
        ),
      ],
    ),
  );
}

/// Пять пар «подпись + значение» в панели полей.
class FieldsPanelSkeleton extends StatelessWidget {
  /// @nodoc
  const FieldsPanelSkeleton({super.key});

  /// Сколько пар показывать.
  static const rows = 5;

  @override
  Widget build(BuildContext context) => SLShimmeringEffect(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows; i++) ...const [
          SLSkeletonLine(width: 64, height: 12),
          SizedBox(height: SLSpacing.space1),
          SLSkeletonLine(width: 140, height: 20),
          SizedBox(height: SLSpacing.space4),
        ],
      ],
    ),
  );
}

/// Три блока-скелетона комментариев.
class CommentsSkeleton extends StatelessWidget {
  /// @nodoc
  const CommentsSkeleton({super.key});

  /// Сколько блоков показывать.
  static const blocks = 3;

  @override
  Widget build(BuildContext context) => SLShimmeringEffect(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks; i++) ...const [
          Row(
            children: [
              SLSkeletonBox.circle(diameter: 24),
              SizedBox(width: SLSpacing.space2),
              SLSkeletonLine(width: 140),
            ],
          ),
          SizedBox(height: SLSpacing.space2),
          SLSkeletonLine(height: 14),
          SizedBox(height: SLSpacing.space1),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.7,
            child: SLSkeletonLine(height: 14),
          ),
          SizedBox(height: SLSpacing.space6),
        ],
      ],
    ),
  );
}

/// Шесть строк-скелетонов истории по 28 (`components.md`, 21).
class HistorySkeleton extends StatelessWidget {
  /// @nodoc
  const HistorySkeleton({super.key});

  /// Сколько строк показывать.
  static const rows = 6;

  /// Высота строки истории.
  static const rowHeight = 28.0;

  @override
  Widget build(BuildContext context) => SLShimmeringEffect(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows; i++)
          const SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                SLSkeletonBox.circle(diameter: 20),
                SizedBox(width: SLSpacing.space2),
                SLSkeletonLine(width: 260),
              ],
            ),
          ),
      ],
    ),
  );
}
