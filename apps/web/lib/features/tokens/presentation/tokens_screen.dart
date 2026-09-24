import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/tokens/domain/token_presentation.dart';
import 'package:sl_tracker_web/features/tokens/presentation/tokens_providers.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/create_token_dialog.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/revoke_token_dialog.dart';
import 'package:sl_tracker_web/features/tokens/presentation/widgets/token_row.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_switch.dart';
import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Экран токенов доступа (`docs/design/screens/tokens.md`).
///
/// Экран личный: «нет прав» у него не бывает, и скрывать его не от кого —
/// токен себе выпускает любой участник, новых прав это не даёт.
///
/// Вся драматургия экрана — в одноразовом показе секрета: его нет в базе,
/// восстановить нельзя. Экран обязан сделать потерю невозможной
/// по невнимательности, но не превратить её в дознание.
class TokensScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const TokensScreen({super.key});

  /// Ширина контента — как у списка доступа: те же административные
  /// пропорции.
  static const contentWidth = 880.0;

  /// Постоянная сноска под таблицей. Суточная гранулярность `lastSeenAt` —
  /// не мелкий шрифт, а причина, по которой колонка говорит «не раньше чем».
  static const footnote =
      'Отметка «Использован» обновляется не чаще раза в сутки: '
      'токен мог работать и позже указанного времени.';

  @override
  ConsumerState<TokensScreen> createState() => _TokensScreenState();
}

class _TokensScreenState extends ConsumerState<TokensScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'tokens-header');
  Timer? _ticker;
  var _now = DateTime.now();

  /// Как часто пересчитываются подписи «через N дней» и «истёк»
  /// в долго открытой вкладке.
  static const _tickPeriod = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    // Фокус на заголовок при входе: скринридер должен сказать, куда человек
    // попал (`screens/README.md`, 6).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _headerFocusNode.requestFocus(),
    );
    _ticker = Timer.periodic(
      _tickPeriod,
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _headerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _create() => CreateTokenDialog.show(context);

  Future<void> _revoke(TokenDto token) async {
    final revoked = await RevokeTokenDialog.show(context, token);
    if (!revoked || !mounted) return;

    // Действия «Отменить» у тоста нет: отзыв необратим, и предлагать
    // несуществующий откат нельзя.
    ref
        .read(toastControllerProvider.notifier)
        .success('Токен «${token.name}» отозван. Агенты с ним потеряли доступ');
  }

  void _setIncludeRevoked({required bool value}) {
    ref.read(tokensIncludeRevokedProvider.notifier).update(value: value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final page = ref.watch(tokensListProvider);
    final includeRevoked = ref.watch(tokensIncludeRevokedProvider);

    final data = page.value;
    // Пустой экран без тулбара — только когда фильтровать действительно
    // нечего: токенов не было вовсе.
    final isBlank =
        data != null &&
        data.items.isEmpty &&
        !includeRevoked &&
        !data.hasRevokedHistory;
    // Во время загрузки тулбар и заголовки колонок отрисованы по-настоящему:
    // они не зависят от содержимого. При ошибке экран занимает состояние
    // ошибки целиком, и фильтровать в нём нечего.
    final showToolbar = !isBlank && !page.hasError;

    return SLShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyN): _create},
      child: ColoredBox(
        color: colors.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TokensScreen.contentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(SLSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    focusNode: _headerFocusNode,
                    // Кнопка активна всегда, в том числе пока список грузится
                    // и когда лимит выбран: отключённая кнопка без объяснения
                    // — худший способ сообщить о лимите.
                    onCreate: _create,
                    isPhone: breakpoint.isPhone,
                  ),
                  const SizedBox(height: SLSpacing.space3),
                  // Снимает ровно то заблуждение, ради которого люди заводят
                  // токены: «это отдельный робот с отдельными правами».
                  const SLBanner(
                    title:
                        'Токен даёт доступ к трекеру от вашего имени — '
                        'с теми же правами, что у вас',
                    description:
                        'Управлять токенами можно только здесь, в браузере.',
                    variant: SLBannerVariant.info,
                  ),
                  if (data != null && data.isAtLimit) ...[
                    const SizedBox(height: SLSpacing.space2),
                    const SLBanner(
                      title: 'Достигнут лимит токенов (20)',
                      description:
                          'Отзовите неиспользуемые, чтобы выпустить новый.',
                      variant: SLBannerVariant.warning,
                    ),
                  ],
                  const SizedBox(height: SLSpacing.space3),
                  // Фильтровать и сортировать нечего, пока список пуст.
                  if (showToolbar) ...[
                    _Toolbar(
                      includeRevoked: includeRevoked,
                      activeCount: data?.activeCount,
                      isPhone: breakpoint.isPhone,
                      onChanged: (value) => _setIncludeRevoked(value: value),
                    ),
                    if (!breakpoint.isPhone)
                      _ColumnHeaders(dense: breakpoint.isTablet),
                  ],
                  Expanded(
                    child: page.when(
                      loading: () => _Skeleton(isPhone: breakpoint.isPhone),
                      error: (error, _) => _buildError(error),
                      data: (data) => _buildList(data, breakpoint),
                    ),
                  ),
                  if (showToolbar) const _Footnote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    // В вебе это состояние недостижимо — cookie-сессия по определению не PAT;
    // текст существует как защита от чужого клиента. Кнопки «Повторить»
    // здесь нет: повтор не поможет.
    if (failure.kind == ApiFailureKind.forbidden) {
      return SLErrorState(
        title: 'Управление токенами доступно только из веб-интерфейса',
        description: 'Откройте трекер в браузере под своим аккаунтом.',
        actionLabel: 'На главную',
        onAction: () => GoRouter.of(context).go(AppRoutes.projects),
        details: failure.toString(),
      );
    }

    return SLErrorState(
      title: 'Не удалось загрузить токены',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      onAction: () => ref.read(tokensListProvider.notifier).refresh(),
      details: failure.toString(),
    );
  }

  Widget _buildList(TokensPage data, SLBreakpoint breakpoint) {
    if (data.items.isEmpty) {
      // Все токены отозваны, а переключатель выключен: показывать «создайте
      // первый» человеку с историей — врать ему про его же прошлое.
      if (data.hasRevokedHistory && !ref.read(tokensIncludeRevokedProvider)) {
        return SLEmptyState(
          icon: Icons.vpn_key_rounded,
          title: 'Действующих токенов нет',
          description:
              'Отозванные скрыты. Включите «Показать отозванные», '
              'чтобы посмотреть историю.',
          actionLabel: 'Показать отозванные',
          actionVariant: SLButtonVariant.ghost,
          onAction: () => _setIncludeRevoked(value: true),
        );
      }

      return SLEmptyState(
        icon: Icons.vpn_key_rounded,
        title: 'Токенов пока нет',
        description:
            'Создайте токен, чтобы подключить агента или скрипт. '
            'Он будет работать от вашего имени и с вашими правами.',
        actionLabel: 'Создать токен',
        onAction: _create,
      );
    }

    final isPhone = breakpoint.isPhone;

    return ListView.builder(
      // Виртуализация: активных токенов максимум 20, но отозванные копятся
      // годами, а пагинации в контракте нет (Q-D38).
      itemExtent: isPhone ? TokenRow.compactHeight : TokenRow.height,
      itemCount: data.items.length,
      itemBuilder: (context, index) {
        final token = data.items[index];

        return TokenRow(
          key: ValueKey(token.id),
          token: token,
          now: _now,
          highlighted: data.highlightedId == token.id,
          compact: isPhone,
          dense: breakpoint.isTablet,
          // Кнопка есть у любого неотозванного токена, включая истёкший:
          // у него она убирает строку из списка.
          onRevoke: token.revokedAt == null ? () => _revoke(token) : null,
        );
      },
    );
  }
}

/// Шапка экрана: заголовок и «Создать токен».
class _Header extends StatelessWidget {
  const _Header({
    required this.focusNode,
    required this.onCreate,
    required this.isPhone,
  });

  final FocusNode focusNode;
  final VoidCallback onCreate;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final title = Focus(
      focusNode: focusNode,
      child: Semantics(
        header: true,
        child: Text(
          'Токены доступа',
          style: text.h2.copyWith(color: colors.textPrimary),
        ),
      ),
    );

    final create = SLButton(
      label: 'Создать токен',
      icon: Icons.add_rounded,
      expand: isPhone,
      onPressed: onCreate,
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: title),
          const SizedBox(height: SLSpacing.space2),
          create,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        create,
      ],
    );
  }
}

/// Тулбар: переключатель отозванных и счётчик действующих.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.includeRevoked,
    required this.activeCount,
    required this.isPhone,
    required this.onChanged,
  });

  final bool includeRevoked;

  /// `null` — список ещё грузится, числа пока нет.
  final int? activeCount;

  final bool isPhone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);
    final count = activeCount;

    final toggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SLSwitch(
          value: includeRevoked,
          semanticsLabel: 'Показать отозванные',
          onChanged: onChanged,
        ),
        // Нажатие по подписи переключает то же самое: попадать
        // в переключатель 32 × 18 мышью — работа, которой можно не делать.
        Flexible(
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => onChanged(!includeRevoked),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'Показать отозванные',
                  style: text.bodyS.copyWith(color: colors.textPrimary),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final counter = Text(
      count == null
          ? 'Активных: — из ${TokenPresentation.activeLimit}'
          : 'Активных: $count из ${TokenPresentation.activeLimit}',
      style: text.label.copyWith(color: colors.textMuted),
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: density.toolbarHeight, child: toggle),
          SizedBox(
            height: 24,
            child: Align(alignment: Alignment.centerLeft, child: counter),
          ),
        ],
      );
    }

    return SizedBox(
      height: density.toolbarHeight,
      child: Row(
        children: [
          Expanded(child: toggle),
          counter,
        ],
      ),
    );
  }
}

/// Заголовки колонок. Сортировки по клику нет: порядок один и задан сервером
/// — по дате создания, новые сверху.
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final style = text.overline.copyWith(color: colors.textMuted);

    return Container(
      height: SLDensity.ofContext(context).tableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
      color: colors.surfaceSunken,
      child: Row(
        children: [
          Expanded(child: Text('ИМЯ', style: style)),
          const SizedBox(width: SLSpacing.space3),
          SizedBox(
            width: TokenRow.prefixColumnWidth,
            child: Text('ПРЕФИКС', style: style),
          ),
          if (!dense)
            SizedBox(
              width: TokenRow.createdColumnWidth,
              child: Text('СОЗДАН', style: style),
            ),
          SizedBox(
            width: TokenRow.lastSeenColumnWidth,
            // Не «ПОСЛЕДНИЙ РАЗ ИСПОЛЬЗОВАН»: при суточной гранулярности это
            // было бы прямой неправдой.
            child: Text('ИСПОЛЬЗОВАН', style: style),
          ),
          SizedBox(
            width: TokenRow.expiresColumnWidth,
            child: Text('ИСТЕКАЕТ', style: style),
          ),
          const SizedBox(width: TokenRow.actionColumnWidth),
        ],
      ),
    );
  }
}

/// Сноска под таблицей.
class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: SLSpacing.space3),
      child: Text(
        TokensScreen.footnote,
        style: text.label.copyWith(color: colors.textMuted),
      ),
    );
  }
}

/// Скелетон списка: четыре строки по геометрии реальных.
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.isPhone});

  final bool isPhone;

  /// Сколько строк-скелетонов показывать.
  static const rowCount = 4;

  @override
  Widget build(BuildContext context) {
    return SLShimmeringEffect(
      // Список, а не `Column`: на низком экране четыре карточки по 100
      // не помещаются, и скелетон не должен ругаться переполнением там,
      // где настоящий список просто прокручивается.
      child: ListView.builder(
        itemExtent: isPhone ? TokenRow.compactHeight : TokenRow.height,
        itemCount: rowCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SLSpacing.space3,
              vertical: SLSpacing.space2,
            ),
            child: isPhone
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SLSkeletonLine(width: 160),
                      SizedBox(height: SLSpacing.space2),
                      SLSkeletonLine(width: 72),
                      SizedBox(height: SLSpacing.space2),
                      SLSkeletonLine(width: 120),
                    ],
                  )
                : Row(
                    children: [
                      const Expanded(
                        child: FractionallySizedBox(
                          widthFactor: 0.45,
                          alignment: Alignment.centerLeft,
                          child: SLSkeletonLine(),
                        ),
                      ),
                      const SizedBox(width: SLSpacing.space3),
                      const SizedBox(
                        width: TokenRow.prefixColumnWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SLSkeletonLine(width: 72),
                        ),
                      ),
                      const SizedBox(
                        width: TokenRow.createdColumnWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SLSkeletonLine(width: 56),
                        ),
                      ),
                      const SizedBox(
                        width: TokenRow.lastSeenColumnWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SLSkeletonLine(width: 56),
                        ),
                      ),
                      const SizedBox(
                        width: TokenRow.expiresColumnWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SLSkeletonLine(width: 56),
                        ),
                      ),
                      const SizedBox(
                        width: TokenRow.actionColumnWidth,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SLSkeletonBox(width: 72, height: 24),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
