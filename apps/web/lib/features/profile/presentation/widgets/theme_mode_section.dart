import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/theme/theme_mode_preference.dart';
import 'package:sl_tracker_web/app/theme/theme_mode_providers.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Выбор темы оформления на экране профиля
/// (`docs/design/screens/profile.md`, «Блок „Оформление“»).
///
/// Три взаимоисключающих варианта, поэтому это группа радиокнопок, а не
/// тумблер: тумблер умеет только «да/нет», а «как в системе» — полноценный
/// третий вариант, и он же значение по умолчанию.
///
/// Раскладка строки повторяет строку настройки уведомления ниже: секции идут
/// подряд, и разнобой в ритме был бы виден.
class ThemeModeSection extends ConsumerWidget {
  /// @nodoc
  const ThemeModeSection({super.key});

  /// Имя группы для скринридера и заголовок секции.
  static const groupLabel = 'Тема оформления';

  /// Название режима.
  static String labelOf(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Как в системе',
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Тёмная',
  };

  /// Уточнение второй строкой. `null` — название говорит само за себя.
  ///
  /// У «как в системе» вторая строка **обязана называть действующую схему**:
  /// без неё человек видит выбранный вариант, но не знает, что он означает
  /// прямо сейчас, — а это единственная информация, ради которой на экран
  /// заходят второй раз. Текст живой: [systemBrightness] приходит из
  /// `MediaQuery`, и строка меняется вместе с настройкой ОС, без перезагрузки.
  static String? hintOf(ThemeMode mode, Brightness systemBrightness) =>
      switch (mode) {
        ThemeMode.system =>
          'Меняется вместе с настройкой системы. '
              'Сейчас ${_schemeName(systemBrightness)}',
        ThemeMode.light => null,
        ThemeMode.dark => null,
      };

  /// Название действующей схемы в винительном виде для второй строки.
  static String _schemeName(Brightness brightness) =>
      brightness == Brightness.dark ? 'тёмная' : 'светлая';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);

    return Semantics(
      container: true,
      label: groupLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mode in SLThemeModePreference.order)
            _ThemeModeRow(
              mode: mode,
              selected: mode == selected,
              // Выбор применяется сразу и не требует подтверждения:
              // он обратим одним нажатием и виден мгновенно.
              onSelect: () =>
                  ref.read(themeModeProvider.notifier).select(mode),
            ),
        ],
      ),
    );
  }
}

/// Строка одного варианта.
///
/// Нажатие по **всей строке**, как в настройках уведомлений рядом: целиться
/// в галочку 16 × 16 мышью — работа, которой можно не делать.
class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({
    required this.mode,
    required this.selected,
    required this.onSelect,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onSelect;

  /// Совпадает с высотой строки настройки уведомления: секции идут одна
  /// под другой, и разнобой в ритме там был бы виден. Строка «как в системе»
  /// выше остальных — 56 против 48, — потому что у неё есть вторая строка.
  static const minHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final label = ThemeModeSection.labelOf(mode);
    // Подписка именно на системную схему, а не на применённую тему: строка
    // «Сейчас тёмная» говорит про настройку ОС и обязана меняться вместе
    // с ней, даже когда выбран явный режим.
    final hint = ThemeModeSection.hintOf(
      mode,
      MediaQuery.platformBrightnessOf(context),
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: hint == null ? label : '$label. $hint',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.borderSubtle,
                width: SLBorders.hairline,
              ),
            ),
          ),
          child: InkWell(
            // Повторное нажатие по выбранному варианту ничего не меняет,
            // но строка остаётся нажимаемой: «мёртвая» строка в списке
            // читается как сломанная.
            onTap: onSelect,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: SLSpacing.space2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: text.bodyS.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          if (hint != null) ...[
                            const SizedBox(height: SLSpacing.space1),
                            Text(
                              hint,
                              style: text.label.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: SLSpacing.space3),
                    // Место под галочку занято всегда: иначе название
                    // выбранного варианта сдвигалось бы относительно
                    // остальных.
                    SizedBox.square(
                      dimension: SLIconSizes.icon20,
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: SLIconSizes.icon20,
                              color: colors.accent,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
