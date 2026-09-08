import 'dart:typed_data';

import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';

/// Запоминает адрес вместо ухода браузера: проверять надо намерение,
/// а не то, что тестовый рендерер умеет менять адресную строку.
class RecordingBrowserNavigator implements BrowserNavigator {
  /// @nodoc
  RecordingBrowserNavigator({this.origin = 'https://tracker.example'});

  /// Куда уходил браузер полным переходом.
  final urls = <String>[];

  /// Что открывали в новой вкладке.
  final newTabUrls = <String>[];

  @override
  final String origin;

  @override
  void assign(String url) => urls.add(url);

  @override
  void openInNewTab(String url) => newTabUrls.add(url);
}

/// Подставной выбор файла: системного диалога в тесте нет.
class FakeFilePicker implements FilePicker {
  /// @nodoc
  FakeFilePicker({this.result});

  /// Что «выберет» человек. `null` — закрыл диалог, ничего не выбрав.
  PickedFile? result;

  /// С каким фильтром звали диалог.
  String? lastAccept;

  /// Сколько раз открывали диалог.
  var calls = 0;

  @override
  Future<PickedFile?> pickOne({required String accept}) async {
    calls++;
    lastAccept = accept;

    return result;
  }
}

/// Файл для тестов загрузки обложки.
PickedFile fakePickedFile({
  String name = 'cover.png',
  String mimeType = 'image/png',
  int size = 1024,
}) => PickedFile(name: name, mimeType: mimeType, bytes: Uint8List(size));
