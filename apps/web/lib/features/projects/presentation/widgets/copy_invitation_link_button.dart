import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';

/// «Скопировать ссылку-приглашение» — приглашающая половина D-04.
///
/// Вторая половина разведения. Её признаки:
///
/// - живёт только на вкладке «Приглашения» и только у администратора;
/// - иконка `person_add_alt_1_rounded` — человек со знаком «плюс»;
/// - до неё надо дойти: выбрать роль, выбрать срок, создать;
/// - рядом написано, что по ссылке в проект войдёт любой;
/// - тост — предупреждение, а не обычное сообщение.
///
/// Слово «адрес» рядом с ней не появляется никогда, а быстрого копирования
/// из шапки, из меню «⋯» и из списка участников у неё нет: единственная
/// точка — эта кнопка.
class CopyInvitationLinkButton extends ConsumerWidget {
  /// @nodoc
  const CopyInvitationLinkButton({
    required this.url,
    this.size = SLButtonSize.sm,
    this.expand = false,
    super.key,
  });

  /// Полная ссылка из ответа сервера.
  ///
  /// Заполнена только у действующего приглашения: у истёкшего и отозванного
  /// её нет и копировать нечего (US-22) — такая кнопка просто не рисуется.
  final String url;

  /// @nodoc
  final SLButtonSize size;

  /// @nodoc
  final bool expand;

  /// Доступное имя. Предупреждение — часть имени, а не только текст рядом:
  /// иначе разведение D-04 не работает в скринридере.
  static const accessibleName =
      'Скопировать ссылку-приглашение. '
      'По ней в проект войдёт любой, у кого она окажется';

  /// Что написано рядом.
  static const explanation =
      'По этой ссылке любой, кто её откроет, войдёт в проект';

  /// Текст тоста. Тост — предупреждение: копирование этой ссылки раздаёт
  /// членство в проекте.
  static const toastMessage =
      'Ссылка-приглашение скопирована. '
      'По ней в проект войдёт любой, у кого она окажется';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      container: true,
      button: true,
      label: accessibleName,
      excludeSemantics: true,
      child: SLButton(
        label: 'Скопировать ссылку',
        icon: Icons.person_add_alt_1_rounded,
        variant: SLButtonVariant.secondary,
        size: size,
        expand: expand,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: url));
          ref
              .read(toastControllerProvider.notifier)
              .show(toastMessage, variant: SLToastVariant.warning);
        },
      ),
    );
  }
}
