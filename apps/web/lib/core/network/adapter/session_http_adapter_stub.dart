import 'package:dio/dio.dart';

/// Реализация для платформ, где браузера нет.
///
/// Возвращает адаптер `dio` по умолчанию. Сессия там будет передаваться
/// bearer-токеном, а не cookie (CLAUDE.md, решение 4).
HttpClientAdapter createSessionHttpAdapter() => HttpClientAdapter();
