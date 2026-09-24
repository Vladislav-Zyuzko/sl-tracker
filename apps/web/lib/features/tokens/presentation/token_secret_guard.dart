import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/platform/unload_guard.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/leave_token_secret_dialog.dart';

/// Показан ли сейчас секрет, который ещё не скопировали.
///
/// Провайдер живёт вне экрана намеренно: уход с экрана перехватывает роутер
/// (`GoRoute.onExit`), а он про виджеты диалога ничего не знает.
///
/// Секрета в состоянии **нет** и быть не может: здесь только флаг «показан»
/// и способ закрыть окно. Сам секрет живёт в памяти виджета и исчезает
/// вместе с ним (`screens/tokens.md`, «Приватность и безопасность»).
final tokenSecretGuardProvider = NotifierProvider<TokenSecretGuard, bool>(
  TokenSecretGuard.new,
);

/// @nodoc
class TokenSecretGuard extends Notifier<bool> {
  VoidCallback? _closeDialog;

  /// Захват на время показа секрета. Держим ссылку, а не читаем провайдер
  /// заново: снимать защиту приходится и при закрытии приложения, когда
  /// контейнер провайдеров уже разобран.
  UnloadGuard? _unloadGuard;

  @override
  bool build() => false;

  /// Включает защиту: [closeDialog] закрывает окно с секретом, когда человек
  /// подтвердил уход.
  void arm(VoidCallback closeDialog) {
    _closeDialog = closeDialog;
    state = true;
    // Подстраховка на закрытие вкладки. Ненадёжна по устройству браузера,
    // поэтому идёт вдобавок к подтверждению, а не вместо него.
    final unloadGuard = ref.read(unloadGuardProvider);
    _unloadGuard = unloadGuard;
    unloadGuard.arm();
  }

  /// Снимает защиту: секрет скопирован или окно закрыто.
  void disarm() {
    _closeDialog = null;
    _unloadGuard?.disarm();
    _unloadGuard = null;
    // Диалог может закрываться уже после того, как провайдеры разобраны
    // (выход из приложения): тогда состояние обновлять некуда и незачем.
    if (ref.mounted) state = false;
  }

  /// Закрывает окно с секретом и снимает защиту.
  void forceClose() {
    final close = _closeDialog;
    disarm();
    close?.call();
  }
}

/// Отпускает ли экран токенов при уходе по роутеру.
///
/// Тот же диалог перехватывает переход по ссылке в оболочке, кнопку «назад»
/// браузера и любой другой уход с `/me/tokens`, пока показан секрет.
Future<bool> confirmLeavingTokenSecret(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  if (!container.read(tokenSecretGuardProvider)) return true;

  final leave = await LeaveTokenSecretDialog.show(context);
  if (!leave) return false;

  // Окно с секретом закрывается вместе с уходом: оставить его поверх нового
  // экрана — значит показать секрет там, где его уже никто не ждёт.
  container.read(tokenSecretGuardProvider.notifier).forceClose();

  return true;
}
