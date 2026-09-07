import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/url_strategy.dart';
import 'package:sl_tracker_web/app/sl_app.dart';

/// Точка входа приложения.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Адреса без решётки: /issues/DEV-42, а не /#/issues/DEV-42 (ADR-0005).
  configureUrlStrategy();

  runApp(const ProviderScope(child: SLApp()));
}
