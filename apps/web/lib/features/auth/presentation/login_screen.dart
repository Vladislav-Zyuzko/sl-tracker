import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/app_config.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_notice.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/yandex_id_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран входа (`docs/design/screens/login.md`).
///
/// Живёт вне оболочки и не содержит ничего, кроме входа: это единственный
/// экран, который видит неаутентифицированный человек.
///
/// Вход — **полный переход браузера** на `/api/auth/yandex/start`, а не XHR:
/// бэкенд отвечает редиректом на Яндекс, и запрос за ним пойти не может
/// (ADR-0002). Всплывающее окно не используется: полный редирект переживает
/// блокировщики попапов и работает на мобильном браузере.
class LoginScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const LoginScreen({
    this.errorCode,
    this.next,
    this.invite,
    this.sessionExpired = false,
    super.key,
  });

  /// Код ошибки из `/login?error=<код>`.
  final String? errorCode;

  /// Адрес назначения: сюда человек попадёт после входа (US-01).
  final String? next;

  /// Токен приглашения, если человек пришёл по ссылке-приглашению (US-21).
  final String? invite;

  /// Сессия была и истекла — показываем спокойный `info`-баннер (US-02).
  final bool sessionExpired;

  /// Ширина блока входа.
  static const blockWidth = 360.0;

  /// Максимальная ширина пояснения под кнопкой.
  static const hintWidth = 320.0;

  /// Высота окна, ниже которой блок прижимается к верху.
  static const shortViewportHeight = 480.0;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Фокус при открытии ставится на заголовок, чтобы скринридер объявил экран.
  /// На кнопку, ведущую на внешний сайт, автофокуса нет намеренно.
  final _headerFocusNode = FocusNode(debugLabel: 'login-header');

  /// Браузер уже уходит на Яндекс. Повторные нажатия игнорируются: страница
  /// всё равно выгружается, а мигать кнопкой не нужно.
  var _redirecting = false;

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

  void _signIn() {
    if (_redirecting) return;
    setState(() => _redirecting = true);

    ref
        .read(browserNavigatorProvider)
        .assign(
          AppConfig.authStartUrl(next: widget.next, invite: widget.invite),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final isResolving = ref.watch(
      sessionControllerProvider.select((session) => session.isResolving),
    );
    final failure = ref.watch(
      sessionControllerProvider.select((session) => session.failure),
    );

    // Приоритет: явная ошибка OAuth из адреса, затем истёкшая сессия,
    // затем сбой проверки сессии.
    final errorCode = widget.errorCode;
    final LoginNotice? notice;
    if (errorCode != null && errorCode.isNotEmpty) {
      notice = LoginNotice.ofOAuthError(errorCode);
    } else if (widget.sessionExpired) {
      notice = LoginNotice.sessionExpired;
    } else {
      notice = LoginNotice.ofFailure(failure);
    }

    final size = MediaQuery.sizeOf(context);
    final isCompact =
        SLBreakpoint.of(context).isPhone ||
        size.height < LoginScreen.shortViewportHeight;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: LoginScreen.blockWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(focusNode: _headerFocusNode),
          const SizedBox(height: SLSpacing.space8),
          if (notice != null) ...[
            SLBanner(
              title: notice.title,
              description: notice.description,
              variant: notice.variant,
              details: notice.details,
            ),
            const SizedBox(height: SLSpacing.space4),
          ],
          if (isResolving)
            const _CompletingSignIn()
          else
            YandexIdButton(
              isLoading: _redirecting,
              // Единственный код, при котором повтор заведомо бессмыслен,
              // — `oauth_not_configured`. Пояснение под кнопкой остаётся.
              onPressed: notice?.blocksSignIn ?? false ? null : _signIn,
            ),
          const SizedBox(height: SLSpacing.space4),
          const _AccessHint(),
        ],
      ),
    );

    final verticalPadding = size.height < LoginScreen.shortViewportHeight
        ? SLSpacing.space6
        : SLSpacing.space8;

    return Scaffold(
      backgroundColor: colors.surfaceSunken,
      body: Semantics(
        container: true,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: SLSpacing.space4,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              // Блок центрируется по вертикали, пока он помещается; если
              // не помещается — страница честно прокручивается.
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 2 * verticalPadding).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              // На телефоне и на низком экране блок прижат к верху:
              // с открытой клавиатурой центрирование выталкивает кнопку
              // за экран.
              child: Align(
                alignment: isCompact ? Alignment.topCenter : Alignment.center,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Заголовок и подзаголовок экрана.
class _Header extends StatelessWidget {
  const _Header({required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'SL Tracker',
              style: text.h1.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: SLSpacing.space2),
          Text(
            'Трекер задач для команды',
            style: text.body.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// «Завершаем вход…» — состояние возврата из Яндекса.
///
/// Скелетона здесь нет намеренно: показывать скелет несуществующего контента
/// нечестно (`screens/login.md`).
class _CompletingSignIn extends StatelessWidget {
  const _CompletingSignIn();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: SLIconSizes.icon16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: SLSpacing.space2),
          Text(
            'Завершаем вход…',
            style: text.bodyS.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Пояснение под кнопкой.
class _AccessHint extends StatelessWidget {
  const _AccessHint();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LoginScreen.hintWidth),
        child: Text(
          'Вход только для участников команды. Нужен доступ — попросите '
          'ссылку-приглашение у администратора проекта.',
          textAlign: TextAlign.center,
          style: text.label.copyWith(color: colors.textMuted),
        ),
      ),
    );
  }
}
