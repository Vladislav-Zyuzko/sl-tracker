import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/features/issues/presentation/issue_realtime.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';

/// Подсветка поля, изменённого другим пользователем
/// (`docs/design/screens/issue.md`, «Поведение»).
///
/// Значение меняется на месте, фон вспыхивает `accentSurface` и гаснет.
/// Ни поле ввода, ни прокрутка при этом не трогаются: внешнее обновление
/// не двигает то, на что человек смотрит.
///
/// Подписка **узкая**: виджет перестраивается, только когда меняется
/// подсветка своего поля, а не на каждое живое событие задачи.
class IssueFieldFlash extends ConsumerWidget {
  /// @nodoc
  const IssueFieldFlash({
    required this.issueKey,
    required this.field,
    required this.child,
    super.key,
  });

  /// Ключ задачи.
  final String issueKey;

  /// Имя поля так, как оно называется в ответе `GET /api/issues/{key}`:
  /// `status`, `priority`, `storyPoints`, `author`, `assignee`, `title`,
  /// `description`, `links`, `attachments`.
  final String field;

  /// Само поле.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashing = ref.watch(
      issueRealtimeProvider(issueKey)
          .select((live) => live.flashingFields.contains(field)),
    );

    return AnimatedContainer(
      duration: SLMotion.durationOf(context, SLMotion.base),
      curve: SLMotion.baseOutCurve,
      decoration: BoxDecoration(
        color: flashing
            ? SLColorScheme.of(context).accentSurface
            : const Color(0x00000000),
        borderRadius: SLRadii.smAll,
      ),
      child: child,
    );
  }
}
