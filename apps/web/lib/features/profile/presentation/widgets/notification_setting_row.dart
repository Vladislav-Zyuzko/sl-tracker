import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_switch.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка настройки уведомления (`docs/design/screens/profile.md`).
///
/// Нажатие по **всей строке** переключает тумблер: попадать в переключатель
/// 32 × 18 мышью — работа, которой можно не делать.
///
/// Доступное имя переключателя — полный текст настройки вместе с уточнением;
/// состояние передаётся флагом `toggled`, а не словами «включено» в имени:
/// скринридер скажет это сам.
class NotificationSettingRow extends StatelessWidget {
  /// @nodoc
  const NotificationSettingRow({
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.hint,
    super.key,
  });

  /// Название типа: «Меня упомянули в тексте».
  final String label;

  /// Уточнение второй строкой. `null` — уточнения нет.
  final String? hint;

  /// Включён ли тип.
  final bool enabled;

  /// @nodoc
  final ValueChanged<bool> onChanged;

  /// Минимальная высота строки. С уточнением строка вырастает — текст
  /// настройки не сокращается никогда, иначе он теряет смысл.
  static const minHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final hint = this.hint;

    return Semantics(
      toggled: enabled,
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
            onTap: () => onChanged(!enabled),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: SLSpacing.space2,
                ),
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
                    SLSwitch(value: enabled, onChanged: onChanged),
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
