import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_avatar_colors.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Обложка проекта с заглушкой-монограммой
/// (`docs/design/screens/projects.md`).
///
/// Один компонент на три места: карточка в списке, шапка проекта и экран
/// приёма приглашения. Заглушка одинакова везде — иначе один и тот же проект
/// без обложки выглядел бы на трёх экранах по-разному.
///
/// Обложка декоративна: рядом всегда написано название проекта, и читать
/// картинку скринридеру незачем.
///
/// **Ссылка живёт 10 минут** (подписанный адрес в `coverUrl`), поэтому
/// надолго её не кэшируем и по истечении срока молча показываем монограмму:
/// иконка «сломанное изображение» здесь не помогает никому.
class SLCoverImage extends StatelessWidget {
  /// @nodoc
  const SLCoverImage({
    required this.projectId,
    required this.projectName,
    required this.coverUrl,
    required this.width,
    required this.height,
    this.borderRadius = SLRadii.mdAll,
    super.key,
  });

  /// Идентификатор проекта: по нему выбирается цвет монограммы, поэтому
  /// переименование проекта цвет не меняет.
  final String projectId;

  /// Название: из него берутся первые две буквы монограммы.
  final String projectName;

  /// Подписанная ссылка. `null` — обложки нет.
  final String? coverUrl;

  /// @nodoc
  final double width;

  /// @nodoc
  final double height;

  /// @nodoc
  final BorderRadius borderRadius;

  /// Прозрачность подложки под монограммой.
  static const monogramSurfaceOpacity = 0.12;

  /// Монограмма: первые две буквы названия, заглавные.
  ///
  /// Если букв не нашлось (название из эмодзи), возвращается пустая строка —
  /// тогда рисуется только подложка, без «?» и прочих извинений.
  static String monogramOf(String name) {
    final letters = name.trim().replaceAll(RegExp(r'\s+'), '');
    if (letters.isEmpty) return '';

    return letters.characters.take(2).toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = coverUrl;

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: url == null
              ? _buildPlaceholder(context)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: width,
                  height: height,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : ColoredBox(
                          color: SLColorScheme.of(context).skeletonBase,
                        ),
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(context),
                ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final fill = SLAvatarColors.of(context).fillOf(projectId);
    final monogram = monogramOf(projectName);

    return ColoredBox(
      color: colors.surfaceSunken,
      child: monogram.isEmpty
          ? const SizedBox.expand()
          : Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: height * 0.12,
                  vertical: height * 0.06,
                ),
                decoration: BoxDecoration(
                  color: fill.withValues(alpha: monogramSurfaceOpacity),
                  borderRadius: SLRadii.smAll,
                ),
                child: Text(
                  monogram,
                  style: _monogramStyle(context).copyWith(color: fill),
                ),
              ),
            ),
    );
  }

  /// Кегль монограммы подбирается по высоте обложки: одна и та же заглушка
  /// стоит и в карточке 158 px, и в шапке 54 px, и `h1` в шапке не поместился
  /// бы.
  TextStyle _monogramStyle(BuildContext context) {
    final text = SLTextScheme.of(context);

    if (height >= 120) return text.h1;
    if (height >= 48) return text.title;

    return text.labelStrong;
  }
}
