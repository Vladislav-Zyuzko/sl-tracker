// Перегенерация API-клиента из контракта одной командой:
//
//     cd apps/web
//     dart run tool/generate_api.dart
//
// Контракт `docs/api/openapi.json` пополняется бэкендом; клиент к нему —
// производная, которую руками не правят (CLAUDE.md, п. 9). Скрипт нужен,
// чтобы добавление эндпоинтов стоило одной команды, а не памяти о трёх.
import 'dart:io';

Future<void> main(List<String> args) async {
  const steps = <(String, List<String>)>[
    // 1. Схема -> клиенты и модели.
    ('dart', ['run', 'swagger_parser']),
    // 2. Модели -> freezed и json_serializable, клиенты -> retrofit.
    ('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']),
    // 3. Сгенерированный код форматируется так же, как остальной:
    //    иначе `dart format --set-exit-if-changed` в CI найдёт различия.
    ('dart', ['format', 'lib/core/api/generated']),
  ];

  for (final (executable, arguments) in steps) {
    stdout.writeln('\n> $executable ${arguments.join(' ')}');

    final result = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );

    final code = await result.exitCode;
    if (code != 0) {
      stderr.writeln('Шаг завершился с кодом $code — генерация прервана.');
      exitCode = code;

      return;
    }
  }

  stdout.writeln(
    '\nГотово. Проверьте `flutter analyze` и загляните в diff: '
    'изменение контракта — это изменение контракта, а не «просто генерация».',
  );
}
