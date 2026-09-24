import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/tokens/domain/token_presentation.dart';
import 'package:sl_tracker_web/features/tokens/presentation/token_secret_guard.dart';
import 'package:sl_tracker_web/features/tokens/presentation/tokens_providers.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/leave_token_secret_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_secret_field.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Выпуск токена доступа (`docs/design/screens/tokens.md`).
///
/// Два шага в одном окне: форма → показ секрета. Между шагами окно
/// **не закрывается**: закрыть и потерять то, ради чего всё затевалось,
/// слишком легко.
///
/// Секрет живёт в памяти этого виджета и исчезает вместе с ним. Он не уходит
/// ни в локальное хранилище, ни в черновики, ни в состояние роутера, ни в
/// логи — это требование к реализации, а не пожелание.
class CreateTokenDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const CreateTokenDialog({super.key});

  /// Пресеты срока (`RFC-MCP-SERVER.md`, §5.3). Произвольного ввода
  /// и «бессрочно» нет ни в интерфейсе, ни в API.
  static const expiryPresets = <int>[30, 90, 365];

  /// Срок по умолчанию.
  static const defaultExpiry = 365;

  /// Максимальная длина названия. Жёсткая: ввод дальше не принимается.
  static const maxNameLength = 64;

  /// Показывает окно.
  ///
  /// `barrierDismissible: false` — на втором шаге клик по подложке не должен
  /// закрывать окно мимо подтверждения, а разрешение зависит от шага
  /// и задаётся один раз при открытии.
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CreateTokenDialog(),
  );

  @override
  ConsumerState<CreateTokenDialog> createState() => _CreateTokenDialogState();
}

class _CreateTokenDialogState extends ConsumerState<CreateTokenDialog> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'token-name');
  final _copyFocusNode = FocusNode(debugLabel: 'token-copy');
  final _secretKey = GlobalKey<SLSecretFieldState>();

  var _expiresInDays = CreateTokenDialog.defaultExpiry;
  var _submitting = false;
  var _copied = false;
  String? _nameError;
  ApiFailure? _failure;
  IssuedTokenDto? _issued;

  /// Охрана секрета берётся сразу и хранится полем: в `dispose` обращаться
  /// к `ref` уже нельзя — виджет к этому моменту отсоединён от дерева.
  late final TokenSecretGuard _guard;

  @override
  void initState() {
    super.initState();
    _guard = ref.read(tokenSecretGuardProvider.notifier);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    _nameFocusNode.dispose();
    _copyFocusNode.dispose();
    // Защита снимается вместе с окном: висящий `beforeunload` спрашивал бы
    // о закрытии вкладки на пустом месте. Снимаем не сразу: менять провайдер
    // во время разборки дерева нельзя.
    scheduleMicrotask(_guard.disarm);
    super.dispose();
  }

  bool get _isSecretStep => _issued != null;

  void _onNameChanged() {
    // Счётчик длины живой, в отличие от валидации: он должен пересчитываться
    // на каждый символ (`components.md`, 3.4).
    setState(() {
      if (_nameError != null) _nameError = null;
    });
  }

  /// Дата, до которой доживёт токен с выбранным сроком.
  ///
  /// Человек выбирает число дней, а живёт с датой — поэтому она пересчитыва-
  /// ется сразу и стоит прямо под выбором.
  DateTime get _expiryDate =>
      DateTime.now().add(Duration(days: _expiresInDays));

  void _close() {
    _guard.disarm();
    Navigator.of(context).pop();
  }

  /// Закрытие второго шага: без копирования — только через подтверждение.
  Future<void> _requestClose() async {
    if (!_isSecretStep || _copied) {
      _close();

      return;
    }

    final leave = await LeaveTokenSecretDialog.show(context);
    if (leave && mounted) _close();
  }

  Future<void> _submit() async {
    if (_submitting || _isSecretStep) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _submitting = true;
      _failure = null;
      _nameError = null;
    });

    try {
      final issued = await ref
          .read(tokensListProvider.notifier)
          .create(name: name, expiresInDays: _expiresInDays);

      if (!mounted) return;

      setState(() {
        _submitting = false;
        _issued = issued;
      });

      // С этого мгновения уход с экрана перехватывается: секрет показан
      // и нигде больше не существует.
      _guard.arm(_close);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        // Введённые название и срок сохраняются: заставлять набирать их
        // заново из-за ошибки сервера — издевательство.
        switch (failure.code) {
          case 'invalid_token_name':
            _nameError = name.length > CreateTokenDialog.maxNameLength
                ? 'Название длиннее 64 символов'
                : 'Название не может быть пустым';
          default:
            _failure = failure;
        }
      });

      // Ошибка поля переводит фокус на поле (`accessibility.md`, 2.7).
      if (_nameError != null) _nameFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final issued = _issued;

    return PopScope(
      // Пока показан секрет, окно не закрывается ни `Esc`, ни кнопкой
      // «назад»: сначала подтверждение.
      canPop: !_isSecretStep && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_isSecretStep) return;
        unawaited(_requestClose());
      },
      child: CallbackShortcuts(
        bindings: {
          // `barrierDismissible` у окна выключен, поэтому `Esc` обрабатываем
          // сами: на шаге 1 он закрывает, на шаге 2 идёт через подтверждение.
          const SingleActivator(LogicalKeyboardKey.escape): _onEscape,
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              _submit,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
          // `Ctrl/Cmd + C` внутри диалога копирует токен. Когда фокус внутри
          // самого значения и текст выделен, сочетание перехватывает
          // выделение — и это правильно: человек копирует то, что выбрал.
          const SingleActivator(LogicalKeyboardKey.keyC, control: true):
              _copySecret,
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
              _copySecret,
        },
        child: issued == null ? _buildForm() : _buildSecretStep(issued),
      ),
    );
  }

  void _onEscape() {
    if (_submitting) return;
    unawaited(_requestClose());
  }

  void _copySecret() {
    if (!_isSecretStep) return;
    unawaited(_secretKey.currentState?.copy() ?? Future<void>.value());
  }

  Widget _buildForm() {
    final page = ref.watch(tokensListProvider).value;
    final atLimit = page?.isAtLimit ?? false;
    final name = _nameController.text.trim();
    final duplicate =
        name.isNotEmpty &&
        (page?.items ?? const <TokenDto>[]).any(
          (token) =>
              TokenPresentation.isActive(token) &&
              token.name.trim().toLowerCase() == name.toLowerCase(),
        );

    return SLDialog(
      title: 'Новый токен',
      onClose: _submitting ? null : _close,
      banner: _buildFormBanner(atLimit: atLimit),
      actions: [
        SLButton(
          label: 'Отмена',
          variant: SLButtonVariant.secondary,
          onPressed: _submitting ? null : _close,
        ),
        SLButton(
          label: 'Создать токен',
          isLoading: _submitting,
          // Пустая форма — не ошибка, а исходное состояние: кнопка просто
          // отключена, красным ничего не подсвечивается.
          onPressed: name.isEmpty || atLimit ? null : _submit,
        ),
      ],
      child: _TokenForm(
        controller: _nameController,
        focusNode: _nameFocusNode,
        errorText: _nameError,
        duplicateName: duplicate,
        expiresInDays: _expiresInDays,
        expiryDate: _expiryDate,
        enabled: !_submitting,
        onExpiryChanged: (days) => setState(() => _expiresInDays = days),
      ),
    );
  }

  Widget? _buildFormBanner({required bool atLimit}) {
    if (atLimit) {
      return const SLBanner(
        title: 'Достигнут лимит токенов (20)',
        description: 'Отзовите неиспользуемые.',
      );
    }

    final failure = _failure;
    if (failure == null) return null;

    final (title, description) = switch (failure.code) {
      'token_limit_reached' => (
        'Достигнут лимит токенов (20)',
        'Отзовите неиспользуемые.',
      ),
      'pat_cannot_manage_tokens' => (
        'Управление токенами доступно только из веб-интерфейса',
        'Откройте трекер в браузере под своим аккаунтом.',
      ),
      _ => switch (failure.kind) {
        ApiFailureKind.conflict => (
          'Достигнут лимит токенов (20)',
          'Отзовите неиспользуемые.',
        ),
        ApiFailureKind.forbidden => (
          'Управление токенами доступно только из веб-интерфейса',
          'Откройте трекер в браузере под своим аккаунтом.',
        ),
        _ when failure.statusCode == 429 => (
          'Слишком много попыток',
          'Подождите минуту и повторите.',
        ),
        _ => ('Не удалось создать токен, повторите', 'Название и срок целы.'),
      },
    };

    return SLBanner(
      title: title,
      description: description,
      details: failure.toString(),
    );
  }

  Widget _buildSecretStep(IssuedTokenDto issued) {
    // Сессия могла истечь, пока человек читал секрет. Выбросить его на вход
    // с непрочитанным токеном — гарантированная потеря токена, поэтому окно
    // остаётся, а истёкшая сессия объявляется баннером.
    final sessionExpired = ref.watch(
      sessionControllerProvider.select((session) => session.isSignedOut),
    );

    return SLDialog(
      title: 'Токен «${issued.name}» создан',
      semanticsLabel:
          'Токен создан. Сохраните его сейчас — '
          'больше он не будет показан',
      onClose: _requestClose,
      banner: sessionExpired
          ? const SLBanner(
              title: 'Сессия в браузере истекла',
              description:
                  'Токен уже создан и продолжает работать — сохраните его, '
                  'затем войдите снова.',
              variant: SLBannerVariant.warning,
            )
          : null,
      actions: [SLButton(label: 'Готово', onPressed: _requestClose)],
      child: _TokenSecretStep(
        secretKey: _secretKey,
        issued: issued,
        copyFocusNode: _copyFocusNode,
        onCopied: () {
          // Признак ставится только при успешном копировании: только он
          // отменяет подтверждение при закрытии.
          if (!_copied) setState(() => _copied = true);
          _guard.disarm();
        },
      ),
    );
  }
}

/// Шаг 1: название и срок.
class _TokenForm extends StatelessWidget {
  const _TokenForm({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.duplicateName,
    required this.expiresInDays,
    required this.expiryDate,
    required this.enabled,
    required this.onExpiryChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool duplicateName;
  final int expiresInDays;
  final DateTime expiryDate;
  final bool enabled;
  final ValueChanged<int> onExpiryChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final length = controller.text.characters.length;
    final expiryText =
        'Токен перестанет работать ${SLDateFormat.long(expiryDate)} года.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SLTextField(
          controller: controller,
          focusNode: focusNode,
          label: 'Название',
          hint: 'dsh-mcp',
          errorText: errorText,
          enabled: enabled,
          autofocus: true,
          maxLength: CreateTokenDialog.maxNameLength,
        ),
        const SizedBox(height: SLSpacing.space1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                errorText == null
                    ? 'Где вы его используете: «dsh-mcp», «ноутбук», «ci».'
                    : '',
                style: text.label.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(width: SLSpacing.space2),
            Text(
              '$length/${CreateTokenDialog.maxNameLength}',
              style: text.label.copyWith(color: colors.textMuted),
            ),
          ],
        ),
        if (duplicateName) ...[
          const SizedBox(height: SLSpacing.space1),
          // Подсказка, а не ошибка: сервер имена не различает, и кнопка
          // остаётся активной.
          Text(
            'Токен с таким названием уже есть — '
            'в списке их будет не отличить.',
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: SLSpacing.space4),
        Text(
          'Срок действия',
          style: text.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SLSpacing.space1),
        RadioGroup<int>(
          groupValue: expiresInDays,
          onChanged: (days) {
            if (days != null && enabled) onExpiryChanged(days);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final days in CreateTokenDialog.expiryPresets)
                _ExpiryOption(
                  days: days,
                  selected: days == expiresInDays,
                  // Выбор «365 дней» сам по себе ничего не говорит о дате,
                  // поэтому дата входит в доступное имя выбранного варианта.
                  semanticsSuffix: days == expiresInDays ? expiryText : null,
                  enabled: enabled,
                  onSelected: () => onExpiryChanged(days),
                ),
            ],
          ),
        ),
        const SizedBox(height: SLSpacing.space1),
        Text(expiryText, style: text.label.copyWith(color: colors.textMuted)),
        const SizedBox(height: SLSpacing.space4),
        // Вариант `warning`, а не `info`: это предупреждение о риске,
        // а не пояснение. Текст — из `SPEC-PAT-API.md`, §5.
        const SLBanner(
          title:
              'Токен даёт доступ к трекеру от вашего имени — '
              'с теми же правами, что у вас',
          description:
              'Не передавайте его третьим лицам; '
              'при утечке отзовите токен здесь.',
          variant: SLBannerVariant.warning,
        ),
      ],
    );
  }
}

/// Строка выбора срока.
///
/// `Radio` в строке `InkWell`, а не `SegmentedButton`: последнего нет
/// в каталоге компонентов, и он потянул бы за собой новую тему.
class _ExpiryOption extends StatelessWidget {
  const _ExpiryOption({
    required this.days,
    required this.selected,
    required this.semanticsSuffix,
    required this.enabled,
    required this.onSelected,
  });

  final int days;
  final bool selected;
  final String? semanticsSuffix;
  final bool enabled;
  final VoidCallback onSelected;

  /// Высота строки выбора.
  static const height = 32.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final label = '$days дней';
    final suffix = semanticsSuffix;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: suffix == null ? label : '$label. $suffix',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: SLRadii.smAll,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              Radio<int>(value: days, enabled: enabled),
              const SizedBox(width: SLSpacing.space1),
              Text(
                label,
                style: text.bodyS.copyWith(
                  color: enabled ? colors.textPrimary : colors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Шаг 2: секрет, показанный один раз.
class _TokenSecretStep extends StatelessWidget {
  const _TokenSecretStep({
    required this.secretKey,
    required this.issued,
    required this.copyFocusNode,
    required this.onCopied,
  });

  final GlobalKey<SLSecretFieldState> secretKey;
  final IssuedTokenDto issued;
  final FocusNode copyFocusNode;
  final VoidCallback onCopied;

  /// Ровно тот вид, в котором токен предъявляется API. Без этой подписи
  /// человек вставит секрет не туда и решит, что токен не работает.
  static const headerExample = 'Authorization: Bearer <токен>';

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Сначала «сохраните сейчас», потом значение: после значения
        // предупреждение уже не читают.
        const SLBanner(
          title: 'Сохраните токен сейчас — больше он не будет показан',
          description:
              'Мы храним только его отпечаток '
              'и восстановить секрет не можем.',
          variant: SLBannerVariant.warning,
        ),
        const SizedBox(height: SLSpacing.space4),
        SLSecretField(
          key: secretKey,
          value: issued.token,
          copyAccessibleName:
              'Скопировать токен в буфер обмена. '
              'Показать его повторно будет нельзя',
          copyAnnouncement: 'Токен скопирован в буфер обмена',
          autofocusCopy: true,
          copyFocusNode: copyFocusNode,
          onCopied: onCopied,
        ),
        const SizedBox(height: SLSpacing.space4),
        Text(
          'Вставьте его в конфигурацию агента как заголовок:',
          style: text.bodyS.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SLSpacing.space1),
        SelectionArea(
          child: Text(
            headerExample,
            style: text.mono.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: SLSpacing.space3),
        Text(
          'Действует до ${SLDateFormat.long(issued.expiresAt)} года.',
          style: text.label.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}
