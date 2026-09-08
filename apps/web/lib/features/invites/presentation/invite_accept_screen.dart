import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/invites/presentation/invite_accept_providers.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/shared/uikit/media/sl_cover_image.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран приёма приглашения (`docs/design/screens/invite-accept.md`).
///
/// Живёт **вне оболочки**: человек может быть ещё не участником и вообще
/// впервые в трекере, и рисовать вокруг сайдбар с чужими данными нельзя.
///
/// Второй сценарий экрана не менее важен первого: отказать так, чтобы отказ
/// ничего не раскрыл. По неизвестному токену нельзя выяснить, существует ли
/// такой проект (US-21) — поэтому «не найдено» и «больше не действует»
/// отличаются только заголовком и не называют проект.
class InviteAcceptScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const InviteAcceptScreen({required this.token, super.key});

  /// Токен приглашения из адреса.
  final String token;

  /// Ширина блока.
  static const blockWidth = 400.0;

  /// Ширина обложки.
  static const coverWidth = 320.0;

  /// Высота обложки — 16:9.
  static const coverHeight = 180.0;

  /// Ниже этой высоты окна обложка скрывается: на маленьком экране решение
  /// принимают по тексту, а не по картинке.
  static const coverMinWindowHeight = 480.0;

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'invite-header');

  ApiFailure? _acceptFailure;
  var _accepting = false;
  var _redirected = false;

  @override
  void dispose() {
    _headerFocusNode.dispose();
    super.dispose();
  }

  /// Уже участник — экран не показывается вовсе (US-21).
  ///
  /// Показывать «вы уже здесь» с кнопкой «Присоединиться» значило бы
  /// предлагать действие, которое ничего не делает.
  void _redirectIfMember(InvitationPreviewDto preview) {
    if (!preview.alreadyMember || _redirected) return;

    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(toastControllerProvider.notifier)
          .show('Вы уже участник этого проекта');
      context.go(AppRoutes.projectPath(preview.projectSlug));
    });
  }

  Future<void> _accept(InvitationPreviewDto preview) async {
    if (_accepting) return;

    setState(() {
      _accepting = true;
      _acceptFailure = null;
    });

    try {
      final result = await ref
          .read(invitePreviewProvider(widget.token).notifier)
          .accept();

      if (!mounted) return;
      ref
          .read(toastControllerProvider.notifier)
          .success(
            result.alreadyMember
                ? 'Вы уже участник проекта «${preview.projectName}»'
                : 'Вы присоединились к проекту «${preview.projectName}»',
          );
      context.go(AppRoutes.projectPath(result.projectSlug));
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _acceptFailure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final preview = ref.watch(invitePreviewProvider(widget.token));

    return Scaffold(
      backgroundColor: colors.surfaceSunken,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SLSpacing.space4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: InviteAcceptScreen.blockWidth,
              ),
              child: preview.when(
                loading: () => const _Skeleton(),
                error: (error, _) => _buildError(error),
                data: _buildInvitation,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Три разных отказа, а не один «что-то пошло не так».
  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    // Сеть: ссылка может быть исправна, и предлагать сдаться рано.
    if (failure.kind == ApiFailureKind.network ||
        failure.kind == ApiFailureKind.timeout ||
        failure.kind == ApiFailureKind.server) {
      return _InviteMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Не удалось проверить приглашение',
        description: 'Проверьте соединение.',
        actionLabel: 'Повторить',
        onAction: () =>
            ref.read(invitePreviewProvider(widget.token).notifier).refresh(),
        assertive: false,
      );
    }

    // 410 — истекло или отозвано. Различать эти два случая снаружи незачем:
    // разница подсказывала бы, что кто-то специально отозвал доступ.
    // 404 — неизвестный токен. Текст тот же с точностью до заголовка:
    // по нему нельзя понять, существует ли такой проект (US-21).
    final isGone = failure.kind == ApiFailureKind.gone;

    return _InviteMessage(
      icon: Icons.link_off_rounded,
      title: isGone
          ? 'Приглашение больше не действует'
          : 'Приглашение не найдено',
      description:
          'Ссылка истекла или её отозвали. '
          'Попросите новую у того, кто вас пригласил.',
      actionLabel: 'На главную',
      onAction: () => context.go(AppRoutes.projects),
      assertive: true,
    );
  }

  Widget _buildInvitation(InvitationPreviewDto preview) {
    _redirectIfMember(preview);
    if (preview.alreadyMember) return const _Skeleton();

    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final role = preview.role.role;
    final failure = _acceptFailure;
    final showCover =
        MediaQuery.sizeOf(context).height >=
        InviteAcceptScreen.coverMinWindowHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCover) ...[
          Center(
            child: SLCoverImage(
              projectId: preview.projectSlug,
              projectName: preview.projectName,
              coverUrl: preview.coverUrl,
              width: InviteAcceptScreen.coverWidth,
              height: InviteAcceptScreen.coverHeight,
              // Подписанная ссылка живёт 10 минут, а страницу приглашения
              // вполне могут открыть и через полчаса: тогда обложка
              // подтянется сама, молча.
              onCoverExpired: () => ref
                  .read(invitePreviewProvider(widget.token).notifier)
                  .refresh(),
            ),
          ),
          const SizedBox(height: SLSpacing.space4),
        ],
        // Фокус при открытии — на названии, а не на кнопке: человек должен
        // прочитать, куда его зовут, до того как нажмёт. Автофокус
        // на «Присоединиться» превратил бы случайный `Enter` во вступление.
        Focus(
          focusNode: _headerFocusNode,
          autofocus: true,
          child: Semantics(
            header: true,
            child: Tooltip(
              message: preview.projectName,
              child: Text(
                preview.projectName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.h2.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: SLSpacing.space2),
        Text(
          'Вас приглашают присоединиться к проекту',
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: SLSpacing.space4),
        _RolePlate(role: role),
        if (failure != null) ...[
          const SizedBox(height: SLSpacing.space4),
          SLBanner(
            title: 'Не удалось присоединиться',
            description: failure.kind == ApiFailureKind.gone
                ? 'Похоже, ссылка перестала действовать.'
                : 'Попробуйте ещё раз.',
            details: failure.toString(),
          ),
        ],
        const SizedBox(height: SLSpacing.space6),
        Semantics(
          button: true,
          // Вне контекста «Присоединиться» непонятно.
          label: 'Присоединиться к проекту ${preview.projectName}',
          child: SLButton(
            label: 'Присоединиться',
            size: SLButtonSize.lg,
            expand: true,
            isLoading: _accepting,
            onPressed: () => _accept(preview),
          ),
        ),
        const SizedBox(height: SLSpacing.space2),
        Center(
          child: SLButton(
            label: 'Не сейчас',
            variant: SLButtonVariant.ghost,
            size: SLButtonSize.sm,
            onPressed: _accepting ? null : () => context.go(AppRoutes.projects),
          ),
        ),
      ],
    );
  }
}

/// Плашка роли: что человек получит и что это значит.
class _RolePlate extends StatelessWidget {
  const _RolePlate({required this.role});

  final SLRole role;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      // Читается целиком, одной фразой.
      label: 'Ваша роль: ${role.label}. ${role.description}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(SLSpacing.space3),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: SLRadii.smAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ваша роль: ${role.label}',
              style: text.bodySStrong.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: SLSpacing.space1),
            Text(
              role.description,
              style: text.label.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Сообщение вместо приглашения: отказ или сбой связи.
class _InviteMessage extends StatelessWidget {
  const _InviteMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.assertive,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  /// Отказ объявляется сразу: человек пришёл по ссылке и должен узнать,
  /// что она не работает, не дожидаясь, пока дойдёт до текста.
  final bool assertive;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      liveRegion: assertive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SLIconSizes.icon48, color: colors.iconMuted),
          const SizedBox(height: SLSpacing.space4),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: text.title.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(height: SLSpacing.space2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: text.body.copyWith(color: colors.textMuted),
            ),
          ),
          const SizedBox(height: SLSpacing.space6),
          SLButton(
            label: actionLabel,
            variant: SLButtonVariant.secondary,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

/// Скелетон в геометрии реального экрана: он показывает, что здесь появится,
/// а спиннер — нет.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const SLShimmeringEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: SLSkeletonBox(
              width: InviteAcceptScreen.coverWidth,
              height: InviteAcceptScreen.coverHeight,
              borderRadius: SLRadii.mdAll,
            ),
          ),
          SizedBox(height: SLSpacing.space4),
          Center(child: SLSkeletonLine(width: 240, height: 20)),
          SizedBox(height: SLSpacing.space2),
          SLSkeletonLine(height: 14),
          SizedBox(height: SLSpacing.space4),
          SLSkeletonBox(height: 56),
          SizedBox(height: SLSpacing.space6),
          SLSkeletonBox(height: 40),
        ],
      ),
    );
  }
}
