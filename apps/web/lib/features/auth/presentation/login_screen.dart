import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран входа (`docs/design/screens/login.md`).
///
/// Живёт вне оболочки. Вход — это **полный переход браузера** на
/// `/api/auth/yandex/start`, а не XHR: бэкенд отвечает редиректом на Яндекс,
/// и запрос за ним пойти не может (ADR-0002). Сам переход подключается вместе
/// с проверкой сессии — сейчас кнопка не активна.
class LoginScreen extends StatelessWidget {
  /// @nodoc
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Scaffold(
      backgroundColor: colors.surfaceSunken,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: SLSizes.dialogSm),
          child: Padding(
            padding: const EdgeInsets.all(SLSpacing.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'SL Tracker',
                    style: text.h1.copyWith(color: colors.textPrimary),
                  ),
                ),
                const SizedBox(height: SLSpacing.space2),
                Text(
                  'Вход по Яндекс ID.',
                  style: text.body.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
