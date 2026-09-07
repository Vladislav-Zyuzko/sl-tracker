import 'package:dio/dio.dart';

import 'package:sl_tracker_web/core/network/adapter/session_http_adapter_stub.dart'
    if (dart.library.js_interop) 'package:sl_tracker_web/core/network/adapter/session_http_adapter_web.dart'
    as impl;

/// Создаёт HTTP-адаптер, умеющий отправлять cookie сессии.
///
/// На вебе это browser-адаптер с `withCredentials: true`: сессия живёт
/// в httpOnly cookie (ADR-0001), и без этого флага браузер её не приложит.
/// На остальных платформах — адаптер `dio` по умолчанию: там сессия поедет
/// bearer-токеном, и веб-специфика в доменный код не протекает.
///
/// Условный импорт нужен, чтобы `dart:js_interop` не попал в мобильную сборку,
/// когда до неё дойдёт дело.
HttpClientAdapter createSessionHttpAdapter() => impl.createSessionHttpAdapter();
