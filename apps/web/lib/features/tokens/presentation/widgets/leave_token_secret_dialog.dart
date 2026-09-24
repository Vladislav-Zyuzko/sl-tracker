import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Подтверждение закрытия окна с несохранённым секретом
/// (`docs/design/screens/tokens.md`).
///
/// Показывается **только если копирование ни разу не выполнялось**: после
/// нажатия «Скопировать» спрашивать «вы скопировали?» — недоверие
/// к собственному интерфейсу.
///
/// Варианта `danger` здесь нет: человек ничего не разрушает, он рискует
/// собственным временем. Фокус — на безопасном «Вернуться», `Esc` означает
/// то же самое.
///
/// Возвращает `true`, если человек всё-таки закрывает окно.
class LeaveTokenSecretDialog extends StatelessWidget {
  /// @nodoc
  const LeaveTokenSecretDialog({super.key});

  /// Показывает окно поверх текущего.
  static Future<bool> show(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => const LeaveTokenSecretDialog(),
    );

    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return SLDialog(
      title: 'Закрыть? Токен больше не показать',
      onClose: () => Navigator.of(context).pop(false),
      actions: [
        SLButton(
          label: 'Всё равно закрыть',
          variant: SLButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SLButton(
          label: 'Вернуться',
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
      child: Text(
        'Секрет не хранится в трекере — мы не сможем показать его снова. '
        'Если вы его не сохранили, вернитесь и скопируйте. '
        'Потерянный токен не чинится: его просто отзывают и выпускают новый.',
        style: text.body.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
