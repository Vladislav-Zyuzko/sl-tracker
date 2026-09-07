import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Реализация для веба.
///
/// `withCredentials: true` обязателен: фронт и API живут на одном домене,
/// сессия — httpOnly cookie, и без этого флага браузер не приложит её
/// к XHR-запросу (ADR-0001).
HttpClientAdapter createSessionHttpAdapter() =>
    BrowserHttpClientAdapter(withCredentials: true);
