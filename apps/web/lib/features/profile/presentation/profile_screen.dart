import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/notifications/domain/notification_setting_text.dart';
import 'package:sl_tracker_web/features/notifications/presentation/notifications_providers.dart';
import 'package:sl_tracker_web/features/profile/presentation/widgets/notification_setting_row.dart';
import 'package:sl_tracker_web/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_owner_badge.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Профиль и настройки уведомлений (`docs/design/screens/profile.md`).
///
/// Данные приходят из Яндекс ID и здесь **не редактируются** (US-04):
/// показываются текстом, а не отключёнными полями ввода — `disabled`-поле
/// обещает, что когда-нибудь станет активным, а здесь этого не будет никогда.
class ProfileScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const ProfileScreen({super.key});

  /// Ширина контента.
  static const contentWidth = 720.0;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'profile-header');

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

  Future<void> _signOut() async {
    try {
      // Подтверждения нет: действие обратимо в одно нажатие. Роутер уведёт
      // на вход сам, как только состояние сессии изменится.
      await ref.read(sessionControllerProvider.notifier).signOut();
    } on Object {
      if (!mounted) return;

      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось выйти',
            actionLabel: 'Повторить',
            onAction: _signOut,
          );
    }
  }

  Future<void> _toggle(
    NotificationSettingDtoType type, {
    required bool enabled,
  }) async {
    try {
      await ref
          .read(notificationSettingsProvider.notifier)
          .toggle(type, enabled: enabled);
    } on Object {
      if (!mounted) return;

      // Откат уже сделал контроллер: здесь остаётся объяснить и предложить
      // повтор. Скринридеру это сообщает живая область тоста.
      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось сохранить настройку',
            actionLabel: 'Повторить',
            onAction: () => _toggle(type, enabled: enabled),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final session = ref.watch(sessionControllerProvider);
    final user = session.user;
    final failure = session.failure;

    if (user == null && failure != null) {
      return SLErrorState(
        title: 'Не удалось загрузить профиль',
        description: 'Проверьте соединение и попробуйте ещё раз.',
        onAction: () => ref.read(sessionControllerProvider.notifier).load(),
        details: failure.toString(),
      );
    }

    // `Material`, а не `ColoredBox`: строки настроек нажимаются целиком.
    return Material(
      color: colors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ProfileScreen.contentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: SLSpacing.space4,
              vertical: SLSpacing.space3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Focus(
                    focusNode: _headerFocusNode,
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Профиль',
                        style: text.h2.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SLSpacing.space6),
                if (user == null)
                  const ProfileIdentitySkeleton()
                else
                  _Identity(user: user, compact: breakpoint.isPhone),
                const SizedBox(height: SLSpacing.space8),
                _SectionTitle('Уведомления'),
                const SizedBox(height: SLSpacing.space3),
                Text(
                  'Присылать уведомления, когда:',
                  style: text.bodyS.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: SLSpacing.space3),
                _Settings(onToggle: _toggle),
                const SizedBox(height: SLSpacing.space8),
                _SectionTitle('Сессия'),
                const SizedBox(height: SLSpacing.space3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SLButton(
                    label: 'Выйти',
                    variant: SLButtonVariant.secondary,
                    expand: breakpoint.isPhone,
                    onPressed: _signOut,
                  ),
                ),
                const SizedBox(height: SLSpacing.space8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Заголовок секции. Тоже заголовок для скринридера: по ним навигируют.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: text.overline.copyWith(color: colors.textMuted),
        ),
      ),
    );
  }
}

/// Блок «кто я»: аватар, имя, адрес и объяснение, почему это не правится.
class _Identity extends StatelessWidget {
  const _Identity({required this.user, required this.compact});

  final MeResponseDto user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    // Имя из Яндекс ID может оказаться пустым: тогда заголовок — адрес,
    // а инициал берётся из него же.
    final displayName = user.displayName.trim().isEmpty
        ? user.email
        : user.displayName;

    final avatar = SLAvatar(
      userId: user.id,
      fullName: displayName,
      photoUrl: user.avatarUrl,
      size: compact ? SLAvatarSize.md : SLAvatarSize.lg,
      decorative: true,
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: displayName,
          child: Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.h2.copyWith(color: colors.textPrimary),
          ),
        ),
        const SizedBox(height: SLSpacing.space1),
        // Адрес выделяется мышью: его копируют, а отдельной кнопки
        // копирования он не заслуживает — это делают редко.
        SelectionArea(
          child: Tooltip(
            message: user.email,
            child: SLMiddleEllipsisText(
              value: user.email,
              style: text.body.copyWith(color: colors.textMuted),
            ),
          ),
        ),
        if (user.isInstanceOwner) ...[
          const SizedBox(height: SLSpacing.space2),
          const Align(
            alignment: Alignment.centerLeft,
            child: SLOwnerBadge(label: 'Владелец трекера'),
          ),
          const SizedBox(height: SLSpacing.space1),
          Text(
            'Вы можете управлять доступом в трекер. '
            'Прав внутри проектов это не даёт.',
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          Align(alignment: Alignment.centerLeft, child: avatar),
          const SizedBox(height: SLSpacing.space2),
          details,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: SLSpacing.space4),
              Expanded(child: details),
            ],
          ),
        const SizedBox(height: SLSpacing.space4),
        // Без этого баннера экран выглядит сломанным: поля есть, а править
        // их нельзя.
        const SLBanner(
          title: 'Имя, email и аватар приходят из вашего аккаунта Яндекса',
          description:
              'Изменить их можно там же, в настройках Яндекс ID. '
              'Здесь они обновляются при каждом входе.',
          variant: SLBannerVariant.info,
        ),
      ],
    );
  }
}

/// Список настроек подписки.
///
/// Ошибка здесь — **частичная** (`components.md`, 17.3): блок «кто я»
/// остаётся на месте, а вместо списка появляется строка с повтором. Валить
/// весь экран из-за списка тумблеров нельзя.
class _Settings extends ConsumerWidget {
  const _Settings({required this.onToggle});

  final Future<void> Function(
    NotificationSettingDtoType type, {
    required bool enabled,
  })
  onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final settings = ref.watch(notificationSettingsProvider);

    if (settings.hasError) {
      return Row(
        children: [
          Text(
            'Не удалось загрузить настройки',
            style: text.label.copyWith(color: colors.textMuted),
          ),
          const SizedBox(width: SLSpacing.space2),
          SLButton(
            label: 'Повторить',
            variant: SLButtonVariant.ghost,
            size: SLButtonSize.sm,
            onPressed: ref.read(notificationSettingsProvider.notifier).refresh,
          ),
        ],
      );
    }

    final items = settings.value;
    if (items == null) return const ProfileSettingsSkeleton();

    final byType = {for (final item in items) item.type: item};

    return Semantics(
      container: true,
      label: 'Присылать уведомления, когда',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in NotificationSettingText.order)
            if (byType[type] case final setting?)
              NotificationSettingRow(
                label: NotificationSettingText.labelOf(type),
                hint: NotificationSettingText.hintOf(type),
                enabled: setting.enabled,
                onChanged: (value) => onToggle(type, enabled: value),
              ),
          if (allNotificationsDisabled(items)) ...[
            const SizedBox(height: SLSpacing.space3),
            // Отключить всё можно, но не молча.
            const SLBanner(
              title: 'Все уведомления отключены',
              description:
                  'Вы не узнаете о назначенных задачах и упоминаниях.',
              variant: SLBannerVariant.warning,
            ),
          ],
        ],
      ),
    );
  }
}
