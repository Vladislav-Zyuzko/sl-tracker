import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/themes/sl_theme_data.dart';

import '../../helpers/pump_widget.dart';

/// Регрессия на живой дефект.
///
/// Слой тостов подключён в `builder` у `MaterialApp.router`, то есть **над**
/// навигатором и его оверлеем. Тултип у кнопки закрытия тоста требует
/// оверлея — и падал с «No Overlay widget found» на любом тосте.
/// В тестах это не всплывало: там хост поднимали как `home`, где оверлей
/// навигатора оказывается сверху.
///
/// Поэтому проверка поднимает приложение ровно так, как оно собрано
/// в `SLApp`, а не так, как удобно тесту.
void main() {
  testWidgets('тост показывается в приложении с роутером и не падает', (
    tester,
  ) async {
    useWindowSize(tester, const Size(1280, 800));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SizedBox.expand()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: SLThemeData.light,
          routerConfig: router,
          builder: (context, child) => SLToastHost(child: child),
        ),
      ),
    );

    container
        .read(toastControllerProvider.notifier)
        .success('Адрес скопирован');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Адрес скопирован'), findsOneWidget);
    // Кнопка закрытия — та самая, из-за тултипа которой всё падало.
    expect(find.byTooltip('Закрыть сообщение'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(SLToastController.dismissDuration);
    await tester.pump();

    expect(find.text('Адрес скопирован'), findsNothing);
  });
}
