import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Один участник в группе аватаров.
@immutable
class SLAvatarGroupMember {
  /// @nodoc
  const SLAvatarGroupMember({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  /// Идентификатор: по нему выбирается цвет заливки.
  final String id;

  /// Полное имя. Попадает в тултип и в доступное имя группы.
  final String name;

  /// @nodoc
  final String? photoUrl;
}

/// Группа аватаров (`docs/design/components.md`, 9.3).
///
/// Показывает первых [maxVisible] и счётчик `+N`. Отдельные аватары
/// из порядка фокуса исключены: фокусируется и озвучивается группа целиком —
/// иначе `Tab` по карточке проекта проходил бы через пять кружков подряд.
class SLAvatarGroup extends StatelessWidget {
  /// @nodoc
  const SLAvatarGroup({
    required this.members,
    required this.total,
    this.maxVisible = 3,
    super.key,
  });

  /// Участники, которых прислал сервер. Порядок — администраторы первыми,
  /// дальше по имени; сортировать здесь нечего.
  final List<SLAvatarGroupMember> members;

  /// Сколько участников всего. Может быть больше длины [members]: сервер
  /// присылает только первых.
  final int total;

  /// Сколько аватаров видно до счётчика.
  final int maxVisible;

  /// На сколько аватары наезжают друг на друга.
  static const overlap = 6.0;

  /// Толщина обводки цветом фона: без неё соседние аватары сливаются.
  static const strokeWidth = 2.0;

  /// Сколько имён помещается в тултип, дальше — «и ещё N».
  static const maxTooltipNames = 10;

  /// Диаметр кружка с учётом обводки.
  static double get _outerDiameter =>
      SLAvatarSize.xs.diameter + strokeWidth * 2;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty && total == 0) return const SizedBox.shrink();

    final visible = members.take(maxVisible).toList();
    final rest = total - visible.length;
    final circles = visible.length + (rest > 0 ? 1 : 0);
    final step = _outerDiameter - overlap;

    return Semantics(
      label: _semanticsLabel(visible, rest),
      excludeSemantics: true,
      child: Tooltip(
        message: _tooltipMessage(),
        child: SizedBox(
          width: circles == 0 ? 0 : step * (circles - 1) + _outerDiameter,
          height: _outerDiameter,
          child: Stack(
            children: [
              for (var index = 0; index < visible.length; index++)
                Positioned(
                  left: step * index,
                  child: _Ring(
                    child: SLAvatar(
                      userId: visible[index].id,
                      fullName: visible[index].name,
                      photoUrl: visible[index].photoUrl,
                      decorative: true,
                    ),
                  ),
                ),
              if (rest > 0)
                Positioned(
                  left: step * visible.length,
                  child: _Ring(child: _MoreCounter(count: rest)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _tooltipMessage() {
    final names = members.take(maxTooltipNames).map((m) => m.name).toList();
    final hidden = total - names.length;

    return hidden > 0 ? '${names.join(', ')} и ещё $hidden' : names.join(', ');
  }

  String _semanticsLabel(List<SLAvatarGroupMember> visible, int rest) {
    final names = visible.map((member) => member.name).join(', ');
    if (names.isEmpty) return 'Участников: $total';

    return rest > 0 ? 'Участники: $names и ещё $rest' : 'Участники: $names';
  }
}

/// Обводка цветом поверхности вокруг кружка.
class _Ring extends StatelessWidget {
  const _Ring({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(SLAvatarGroup.strokeWidth),
    decoration: BoxDecoration(
      color: SLColorScheme.of(context).surface,
      shape: BoxShape.circle,
    ),
    child: child,
  );
}

/// Счётчик «+N» на месте четвёртого аватара.
class _MoreCounter extends StatelessWidget {
  const _MoreCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      width: SLAvatarSize.xs.diameter,
      height: SLAvatarSize.xs.diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        shape: BoxShape.circle,
      ),
      child: Text(
        '+$count',
        style: text.overline.copyWith(
          color: colors.textSecondary,
          fontSize: SLAvatarSize.xs.initialsSize,
        ),
      ),
    );
  }
}
