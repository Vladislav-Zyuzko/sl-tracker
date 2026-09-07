import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_avatar_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

/// Размер аватара (`docs/design/components.md`, 9.2).
enum SLAvatarSize {
  /// 20. Строка списка, селектор, группа аватаров.
  xs(20, 9),

  /// 24. Сайдбар задачи, шапка комментария.
  sm(24, 10),

  /// 32. Список участников, меню профиля.
  md(32, 13),

  /// 48. Страница профиля.
  lg(48, 20);

  /// @nodoc
  const SLAvatarSize(this.diameter, this.initialsSize);

  /// Диаметр круга.
  final double diameter;

  /// Кегль инициалов.
  final double initialsSize;
}

/// Аватар пользователя.
///
/// Без фотографии — инициалы на детерминированной заливке по идентификатору
/// пользователя. Если фото не загрузилось, молча падаем на инициалы: иконка
/// «сломанное изображение» здесь не нужна никому.
class SLAvatar extends StatelessWidget {
  /// @nodoc
  const SLAvatar({
    required this.userId,
    required this.fullName,
    this.photoUrl,
    this.size = SLAvatarSize.xs,
    this.decorative = false,
    super.key,
  });

  /// Идентификатор пользователя. По нему выбирается цвет заливки: смена имени
  /// не должна менять цвет аватара.
  final String userId;

  /// Полное имя. Из него берутся инициалы, оно же — доступное имя.
  final String fullName;

  /// Ссылка на фотографию.
  final String? photoUrl;

  /// @nodoc
  final SLAvatarSize size;

  /// Аватар внутри строки, где имя и так написано текстом, — декоративен
  /// и из семантики исключается.
  final bool decorative;

  /// Инициалы: первые буквы имени и фамилии, заглавные.
  ///
  /// Пустая строка означает, что имени нет вовсе — тогда рисуется иконка.
  static String initialsOf(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();

    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final avatarColors = SLAvatarColors.of(context);
    final initials = initialsOf(fullName);
    final fill = initials.isEmpty
        ? avatarColors.fills.first
        : avatarColors.fillOf(userId);

    final avatar = SizedBox.square(
      dimension: size.diameter,
      child: ClipOval(
        child: ColoredBox(
          color: fill,
          child: photoUrl == null
              ? _buildInitials(colors, initials)
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : ColoredBox(color: colors.skeletonBase),
                  errorBuilder: (context, error, stackTrace) =>
                      _buildInitials(colors, initials),
                ),
        ),
      ),
    );

    if (decorative) return ExcludeSemantics(child: avatar);

    return Semantics(
      label: fullName,
      image: photoUrl != null,
      child: ExcludeSemantics(child: avatar),
    );
  }

  Widget _buildInitials(SLColorScheme colors, String initials) {
    if (initials.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: size.diameter * 0.6,
        color: colors.textOnAccent,
      );
    }

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size.initialsSize,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: colors.textOnAccent,
        ),
      ),
    );
  }
}

/// Группа аватаров участников (`docs/design/components.md`, 9.3).
///
/// Показываются первые три, дальше счётчик. Отдельные аватары из порядка
/// фокуса исключаются: фокусируется вся группа целиком.
class SLAvatarGroup extends StatelessWidget {
  /// @nodoc
  const SLAvatarGroup({required this.members, this.maxVisible = 3, super.key});

  /// Участники в порядке показа: администраторы первыми, дальше по алфавиту.
  final List<SLAvatarData> members;

  /// Сколько аватаров показывать до счётчика.
  final int maxVisible;

  /// Перекрытие соседних аватаров.
  static const overlap = 6.0;

  /// Толщина обводки, отделяющей аватары друг от друга.
  static const strokeWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final colors = SLColorScheme.of(context);
    final visible = members.take(maxVisible).toList();
    final hidden = members.length - visible.length;
    const diameter = 20.0;
    const step = diameter + strokeWidth * 2 - overlap;
    final itemCount = visible.length + (hidden > 0 ? 1 : 0);

    return Semantics(
      label: _accessibleLabel(hidden),
      child: ExcludeSemantics(
        child: SizedBox(
          width: diameter + strokeWidth * 2 + step * (itemCount - 1),
          height: diameter + strokeWidth * 2,
          child: Stack(
            children: [
              for (var i = 0; i < visible.length; i++)
                Positioned(
                  left: step * i,
                  child: _ringed(
                    colors,
                    SLAvatar(
                      userId: visible[i].userId,
                      fullName: visible[i].fullName,
                      photoUrl: visible[i].photoUrl,
                      decorative: true,
                    ),
                  ),
                ),
              if (hidden > 0)
                Positioned(
                  left: step * visible.length,
                  child: _ringed(colors, _CounterBubble(count: hidden)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ringed(SLColorScheme colors, Widget child) => Container(
    padding: const EdgeInsets.all(strokeWidth),
    decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
    child: child,
  );

  String _accessibleLabel(int hidden) {
    final names = members
        .take(maxVisible)
        .map((member) => member.fullName)
        .join(', ');

    return hidden > 0 ? 'Участники: $names и ещё $hidden' : 'Участники: $names';
  }
}

/// Кружок «+N» в конце группы аватаров.
class _CounterBubble extends StatelessWidget {
  const _CounterBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Container(
      width: SLAvatarSize.xs.diameter,
      height: SLAvatarSize.xs.diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: SLRadii.fullAll,
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: SLAvatarSize.xs.initialsSize,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

/// Данные участника для аватара.
class SLAvatarData {
  /// @nodoc
  const SLAvatarData({
    required this.userId,
    required this.fullName,
    this.photoUrl,
  });

  /// @nodoc
  final String userId;

  /// @nodoc
  final String fullName;

  /// @nodoc
  final String? photoUrl;
}
