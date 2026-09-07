import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Временная заглушка экрана.
///
/// Нужна ровно для того, чтобы маршруты, параметры и глубокие ссылки работали
/// по-настоящему до того, как появятся данные. Каждая заглушка заменяется
/// реальным экраном по мере готовности контракта API и спеки; когда заменена
/// последняя, этот файл удаляется.
///
/// Заголовок получает фокус при открытии экрана: при переходе между экранами
/// фокус ставится на `h2` нового экрана, чтобы скринридер объявил, куда попал
/// (`docs/design/screens/README.md`, 6).
class PlaceholderScreen extends StatefulWidget {
  /// @nodoc
  const PlaceholderScreen({
    required this.title,
    required this.description,
    this.parameters = const {},
    super.key,
  });

  /// Заголовок экрана.
  final String title;

  /// Что этот экран будет делать.
  final String description;

  /// Параметры маршрута, разобранные роутером. Показываются, чтобы глубокую
  /// ссылку можно было проверить глазами.
  final Map<String, String> parameters;

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'screen-header');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _headerFocusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _headerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SLSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            focusNode: _headerFocusNode,
            child: Semantics(
              header: true,
              child: Text(
                widget.title,
                style: text.h2.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: SLSpacing.space2),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SLSizes.readableTextWidth,
            ),
            child: SelectionArea(
              child: Text(
                widget.description,
                style: text.body.copyWith(color: colors.textMuted),
              ),
            ),
          ),
          if (widget.parameters.isNotEmpty) ...[
            const SizedBox(height: SLSpacing.space4),
            for (final entry in widget.parameters.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: SLSpacing.space1),
                child: SelectionArea(
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: text.mono.copyWith(color: colors.textSecondary),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
