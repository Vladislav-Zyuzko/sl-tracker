import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

/// Экран «Страница не найдена».
///
/// Показывается и когда адреса нет, и когда раздел есть, но пользователю
/// о нём знать не положено: «невидимость вместо запрета»
/// (`docs/product/permissions.md`, п. 5). Поэтому текст один и тот же —
/// по нему нельзя понять, существует раздел или нет.
class NotFoundScreen extends StatelessWidget {
  /// @nodoc
  const NotFoundScreen({this.location, super.key});

  /// Адрес, который не открылся. Виден только в блоке «Подробности».
  final String? location;

  @override
  Widget build(BuildContext context) => Scaffold(
    // Собственный `Scaffold` нужен потому, что экран открывается и вне
    // оболочки — по неизвестному адресу, где никакого каркаса вокруг нет.
    backgroundColor: SLColorScheme.of(context).surface,
    body: SLErrorState(
      title: 'Страница не найдена',
      description: 'Проверьте адрес: возможно, в ссылке опечатка.',
      actionLabel: 'К списку проектов',
      onAction: () => GoRouter.of(context).go(AppRoutes.projects),
      details: location,
    ),
  );
}
