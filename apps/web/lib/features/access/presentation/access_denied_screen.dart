import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/features/access/presentation/access_denied_providers.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран «Доступ к трекеру закрыт» (`docs/design/screens/access-denied.md`).
///
/// Вне оболочки: сессии нет и пользователя в базе нет (US-05). Экран не
/// раскрывает о трекере ничего — ни названий, ни людей, ни контактов.
/// Единственное персональное на нём — адрес, под которым человек вошёл:
/// он его и так знает, зато это снимает самый частый случай «вошёл не тем
/// аккаунтом».
///
/// Адрес берётся **обменом одноразового тикета**, а не из адресной строки:
/// в адрес и в логи он не попадает.
class AccessDeniedScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const AccessDeniedScreen({this.ticket, super.key});

  /// Одноразовый тикет из адреса. `null` — человек пришёл на экран напрямую,
  /// без редиректа от бэкенда.
  final String? ticket;

  /// Ширина блока.
  static const blockWidth = 400.0;

  /// Максимальная ширина текста.
  static const textWidth = 360.0;

  /// Максимальная ширина адреса в тексте.
  static const emailWidth = 320.0;

  /// Высота окна, ниже которой иконка уменьшается, а отступы сжимаются.
  static const shortViewportHeight = 480.0;

  @override
  ConsumerState<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends ConsumerState<AccessDeniedScreen> {
  /// Фокус при открытии — на заголовке, чтобы скринридер объявил суть экрана.
  /// Автофокуса на «Выйти» нет: случайный `Enter` не должен выкидывать
  /// человека до того, как он прочитал, что произошло.
  final _headerFocusNode = FocusNode(debugLabel: 'access-denied-header');

  var _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _headerFocusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _headerFocusNode.dispose();
    super.dispose();
  }

  /// Гасит сессию, если она вообще была создана, и уводит на вход.
  ///
  /// Сессия в Яндексе при этом не трогается (US-03): выбирать аккаунт человек
  /// будет уже на стороне Яндекса.
  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);

    try {
      await ref.read(sessionControllerProvider.notifier).signOut();
      if (mounted) context.go(AppRoutes.login);
    } on Object {
      // Человек не заперт: «Войти другим аккаунтом» работает независимо.
      if (!mounted) return;
      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось выйти',
            actionLabel: 'Повторить',
            onAction: _signOut,
          );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  /// «Войти другим аккаунтом»: выход и переход на вход.
  ///
  /// Ошибка выхода здесь не показывается тостом: сессии, скорее всего, и не
  /// было, а уйти на экран входа человек должен в любом случае.
  Future<void> _signInAsSomeoneElse() async {
    try {
      await ref.read(sessionControllerProvider.notifier).signOut();
    } on Object {
      // Осознанно проглочено: см. комментарий выше.
    }

    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isShort = size.height < AccessDeniedScreen.shortViewportHeight;
    final isCompact = SLBreakpoint.of(context).isPhone || isShort;

    final ticket = widget.ticket;
    final email = ticket == null
        ? const AsyncValue<String?>.data(null)
        : ref.watch(accessDeniedEmailProvider(ticket));

    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AccessDeniedScreen.blockWidth,
      ),
      child: Semantics(
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Замок — `iconMuted`, а не `danger`: человек ничего не сломал
            // и не нарушил, красный замок здесь обвиняет.
            Icon(
              Icons.lock_outline_rounded,
              size: isShort ? SLIconSizes.icon24 : SLIconSizes.icon48,
              color: colors.iconMuted,
            ),
            SizedBox(height: isShort ? SLSpacing.space4 : SLSpacing.space4),
            Focus(
              focusNode: _headerFocusNode,
              child: Semantics(
                header: true,
                child: Text(
                  'Доступ к трекеру закрыт',
                  textAlign: TextAlign.center,
                  style: SLTextScheme.of(context).title
                      .copyWith(color: colors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: SLSpacing.space2),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AccessDeniedScreen.textWidth,
                ),
                child: SLLoadingGate(
                  isLoading: email.isLoading,
                  skeleton: const _ExplanationSkeleton(),
                  child: _Explanation(email: email.value),
                ),
              ),
            ),
            SizedBox(height: isShort ? SLSpacing.space4 : SLSpacing.space6),
            // Основной кнопки на экране нет намеренно: главного действия
            // здесь не существует. Обе кнопки — способы уйти.
            SLButton(
              label: 'Выйти',
              variant: SLButtonVariant.secondary,
              expand: true,
              isLoading: _signingOut,
              onPressed: _signOut,
            ),
            const SizedBox(height: SLSpacing.space2),
            SLButton(
              label: 'Войти другим аккаунтом',
              variant: SLButtonVariant.ghost,
              size: SLButtonSize.sm,
              onPressed: _signInAsSomeoneElse,
            ),
          ],
        ),
      ),
    );

    final verticalPadding = isShort ? SLSpacing.space4 : SLSpacing.space8;

    return Scaffold(
      backgroundColor: colors.surfaceSunken,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: SLSpacing.space4,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 2 * verticalPadding).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Align(
              alignment: isCompact ? Alignment.topCenter : Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Объяснение происходящего.
///
/// Текст не различает «вас нет в списке» и «приглашение просрочено»:
/// оба случая выглядят одинаково, иначе экран становится оракулом
/// для перебора адресов.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final bodyStyle = text.body.copyWith(color: colors.textMuted);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (email == null)
          Text(
            'Этот аккаунт не входит в число тех, кому открыт доступ.',
            textAlign: TextAlign.center,
            style: bodyStyle,
          )
        else ...[
          Text('Вы вошли как', textAlign: TextAlign.center, style: bodyStyle),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AccessDeniedScreen.emailWidth,
            ),
            child: SLMiddleEllipsisText(
              value: email!,
              style: text.bodyStrong.copyWith(color: colors.textPrimary),
            ),
          ),
          Text(
            'Этого аккаунта нет среди тех, кому открыт доступ.',
            textAlign: TextAlign.center,
            style: bodyStyle,
          ),
        ],
        const SizedBox(height: SLSpacing.space4),
        Text(
          'Чтобы попасть внутрь, попросите ссылку-приглашение у того, '
          'кто позвал вас в команду.',
          textAlign: TextAlign.center,
          style: bodyStyle,
        ),
      ],
    );
  }
}

/// Скелетон текста, пока меняется тикет.
///
/// Появляется только если обмен затянулся: на быстром ответе экран
/// не мигает (`components.md`, 15).
class _ExplanationSkeleton extends StatelessWidget {
  const _ExplanationSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SLSkeletonLine(width: 220, height: 14),
      SizedBox(height: SLSpacing.space2),
      SLSkeletonLine(width: 280, height: 14),
      SizedBox(height: SLSpacing.space2),
      SLSkeletonLine(width: 180, height: 14),
    ],
  );
}
