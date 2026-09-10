import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/core/platform/file_drop.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/core/realtime/realtime_client.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_attachments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_comments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_history_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_realtime.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/comment_composer.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/comment_item.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/comments_sliver.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/history_sliver.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_attachments.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_description.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_fields.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_fields_panel.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_header.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_links.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_skeletons.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/features/realtime/presentation/realtime_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/navigation/sl_tabs.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Вкладка ленты: обсуждение или журнал изменений.
enum IssueTab {
  /// Комментарии. Всегда выбрана при открытии задачи, даже если их нет.
  comments,

  /// История. Живёт вкладкой, а не блоком под комментариями: у лент разная
  /// частота обращения, противоположная сортировка и своя пагинация.
  history,
}

/// Экран задачи (`docs/design/screens/issue.md`).
///
/// Самый дорогой экран продукта. Устройство:
///
/// * **одна ось прокрутки** — `CustomScrollView`: содержимое, вкладки и лента
///   живут в одном скролле, а панель полей справа залипает отдельной
///   колонкой. Вторая полоса прокрутки внутри страницы ломает колесо мыши;
/// * **лента виртуализирована** `SliverList.builder`, без `itemExtent`:
///   высоту комментария задаёт Markdown внутри него;
/// * **правки полей оптимистичны** и откатываются полем, а не перезагрузкой
///   всей задачи;
/// * права берутся из `permissions`, а не из роли.
class IssueScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const IssueScreen({required this.issueKey, this.anchorCommentId, super.key});

  /// Ключ задачи вида `DEV-42`. Публичный идентификатор: ссылка на задачу
  /// стабильна и человекочитаема (ADR-0004, ADR-0005).
  final String issueKey;

  /// Комментарий из `?comment=<id>`: экран прокручивается к нему и подсвечивает
  /// его (US-102, US-104).
  final String? anchorCommentId;

  /// Ширина читаемой колонки.
  static const contentMaxWidth = SLSizes.readableTextWidth;

  /// Сколько порций более ранних комментариев подгружается в поисках якоря,
  /// прежде чем признать его недостижимым.
  static const anchorLookupPages = 3;

  /// Насколько близко к концу ленты человек считается «внизу».
  static const atBottomThreshold = 48.0;

  @override
  ConsumerState<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends ConsumerState<IssueScreen> {
  final _scrollController = ScrollController();
  final _commentKeys = <String, GlobalKey>{};
  final _statusFieldKey = GlobalKey<IssueStatusFieldState>();
  final _assigneeFieldKey = GlobalKey<IssueUserFieldState>();
  final _composerKey = GlobalKey<CommentComposerState>();
  final _composerFocus = FocusNode(debugLabel: 'issue-composer');

  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();

  VoidCallback? _detachDrop;

  var _tab = IssueTab.comments;
  var _editingDescription = false;
  var _savingDescription = false;
  var _dropActive = false;
  String? _highlightedCommentId;
  String? _editingCommentId;
  var _anchorResolved = false;
  var _anchorAttempts = 0;

  @override
  void initState() {
    super.initState();
    _highlightedCommentId = widget.anchorCommentId;
    _attachDropTarget();
    _scrollController.addListener(_onScroll);
  }

  /// Человек доехал до конца ленты — плашка «Новых комментариев» больше
  /// не нужна: он их и так видит.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter >
        IssueScreen.atBottomThreshold) {
      return;
    }

    ref
        .read(issueRealtimeProvider(widget.issueKey).notifier)
        .clearNewComments();
  }

  /// Прокручивает ленту вниз по нажатию на плашку.
  Future<void> _scrollToNewComments() async {
    ref
        .read(issueRealtimeProvider(widget.issueKey).notifier)
        .clearNewComments();

    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: SLMotion.durationOf(context, SLMotion.base),
      curve: SLMotion.baseInCurve,
    );
  }

  /// Перечитывает всё, что показывает экран.
  ///
  /// Кнопка «Обновить» в баннере устаревших данных и восстановление связи
  /// делают ровно это: данные едут обычными запросами, а не «доигрываются»
  /// из пропущенных событий (`websocket.md`, 1).
  void _refreshAll() {
    _issueNotifier.refresh();
    _commentsNotifier.reload();
    ref.read(issueHistoryProvider(widget.issueKey).notifier).refresh();
  }

  /// Задачу удалил другой пользователь.
  ///
  /// Экран закрывается сразу, а не «при следующем действии»: сидеть
  /// на карточке того, чего уже нет, — худшее из состояний.
  void _onDeletedElsewhere() {
    if (!mounted) return;

    final queueKey = _issue?.queue.key;
    ref
        .read(toastControllerProvider.notifier)
        .show('Задачу удалили', variant: SLToastVariant.info);
    context.go(
      queueKey == null ? AppRoutes.projects : AppRoutes.queuePath(queueKey),
    );
  }

  @override
  void dispose() {
    _detachDrop?.call();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _composerFocus.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// Подписка на перетаскивание файлов из проводника.
  ///
  /// Отписка обязательна: слушатель висит на документе, и без неё уход
  /// с экрана оставил бы перехват `drop` навсегда.
  void _attachDropTarget() {
    _detachDrop = ref
        .read(fileDropTargetProvider)
        .attach(
          onHoverChanged: (hovering) {
            if (mounted) setState(() => _dropActive = hovering);
          },
          onFiles: _uploadFiles,
        );
  }

  // --- Данные ---------------------------------------------------------------

  IssueDto? get _issue => ref.read(issueProvider(widget.issueKey)).value;

  String? get _currentUserId =>
      ref.read(sessionControllerProvider).user?.id;

  // --- Действия -------------------------------------------------------------

  void _toast(String message) =>
      ref.read(toastControllerProvider.notifier).show(message);

  /// Показывает ошибку правки и предлагает повтор.
  ///
  /// Отдельные коды отказа экран обязан различать: выбранного человека могли
  /// исключить из проекта, пока список был открыт.
  void _reportFailure(Object error, String fallback, VoidCallback retry) {
    final failure = ApiFailure.of(error);
    final toasts = ref.read(toastControllerProvider.notifier);

    if (failure.code == 'assignee_not_member' ||
        failure.code == 'author_not_member') {
      // Список участников устарел — перезапрашиваем его целиком.
      ref.invalidate(issueMembersProvider);
      toasts.error('Выбранный человек больше не участник проекта');

      return;
    }

    if (failure.kind == ApiFailureKind.notFound) {
      toasts.show('Задачу удалили', variant: SLToastVariant.info);
      ref.read(issueProvider(widget.issueKey).notifier).refresh();

      return;
    }

    toasts.error(fallback, actionLabel: 'Повторить', onAction: retry);
  }

  /// Оборачивает оптимистичную правку: контроллер уже откатил поле,
  /// здесь остаётся объяснить и предложить повтор.
  Future<void> _edit(
    Future<void> Function() action,
    String failureMessage,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) return;

      _reportFailure(
        error,
        failureMessage,
        () => _edit(action, failureMessage),
      );
    }
  }

  IssueController get _issueNotifier =>
      ref.read(issueProvider(widget.issueKey).notifier);

  IssueFieldsActions get _fieldsActions => IssueFieldsActions(
    onStatusChanged: (status) => _edit(
      () => _issueNotifier.changeStatus(status),
      'Не удалось изменить статус',
    ),
    onPriorityChanged: (value) => _edit(
      () => _issueNotifier.changePriority(value),
      'Не удалось изменить приоритет',
    ),
    onStoryPointsChanged: (value) => _edit(
      () => _issueNotifier.changeStoryPoints(value),
      'Не удалось изменить сложность',
    ),
    onAuthorChanged: (user) => _edit(
      () => _issueNotifier.changeAuthor(user),
      'Не удалось изменить автора',
    ),
    onAssigneeChanged: (user) => _edit(
      () => _issueNotifier.changeAssignee(user),
      'Не удалось изменить исполнителя',
    ),
    onAssignToMe: _assignToMe,
    onClearAssignee: () => _edit(
      () => _issueNotifier.changeAssignee(null),
      'Не удалось снять исполнителя',
    ),
  );

  void _assignToMe() {
    final session = ref.read(sessionControllerProvider).user;
    if (session == null) return;

    _edit(
      () => _issueNotifier.changeAssignee(
        IssueUserDto(
          id: session.id,
          displayName: session.displayName,
          avatarUrl: session.avatarUrl,
        ),
      ),
      'Не удалось назначить задачу на себя',
    );
  }

  Future<void> _copyKey() async {
    await Clipboard.setData(ClipboardData(text: widget.issueKey));
    if (mounted) _toast('Ключ скопирован');
  }

  Future<void> _copyLink() async {
    final navigator = ref.read(browserNavigatorProvider);
    final url = '${navigator.origin}${AppRoutes.issuePath(widget.issueKey)}';

    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) _toast('Ссылка скопирована');
  }

  void _openLink(String url) {
    // Схему уже проверил рендерер, но проверка стоит копейки, а доверять
    // адресу из чужого текста нельзя ни на одном слое.
    if (!isOpenableLink(url)) return;

    ref.read(browserNavigatorProvider).openInNewTab(url);
  }

  Future<void> _deleteIssue() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Удалить задачу ${widget.issueKey}?',
      description:
          'Вместе с задачей исчезнут её комментарии, вложения, ссылки '
          'и история. Действие необратимо, номер задачи повторно '
          'не выдаётся.',
      confirmLabel: 'Удалить задачу',
    );
    if (!confirmed || !mounted) return;

    final queueKey = _issue?.queue.key;

    try {
      await _issueNotifier.remove();
      if (!mounted) return;

      _toast('Задача ${widget.issueKey} удалена');
      context.go(
        queueKey == null ? AppRoutes.projects : AppRoutes.queuePath(queueKey),
      );
    } on Object {
      if (mounted) {
        ref
            .read(toastControllerProvider.notifier)
            .error('Не удалось удалить задачу');
      }
    }
  }

  // --- Описание -------------------------------------------------------------

  void _startEditingDescription() {
    final issue = _issue;
    if (issue == null || !issue.permissions.canEdit) return;

    _descriptionController.text = issue.description ?? '';
    setState(() => _editingDescription = true);
  }

  Future<void> _saveDescription() async {
    setState(() => _savingDescription = true);

    try {
      await _issueNotifier.saveDescription(_descriptionController.text);
      if (!mounted) return;

      setState(() {
        _editingDescription = false;
        _savingDescription = false;
      });
    } on Object {
      if (!mounted) return;

      setState(() => _savingDescription = false);
      // Конфликта редактирования у описания не бывает: продукт сознательно
      // решил не разрешать одновременную правку, побеждает последняя запись
      // (D-27 закрыт). Поэтому здесь один путь — обычная ошибка с повтором.
      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось сохранить описание',
            actionLabel: 'Повторить',
            onAction: _saveDescription,
          );
    }
  }

  // --- Комментарии ----------------------------------------------------------

  CommentsController get _commentsNotifier =>
      ref.read(issueCommentsProvider(widget.issueKey).notifier);

  void _sendComment() {
    final session = ref.read(sessionControllerProvider).user;
    final body = _commentController.text.trim();
    if (session == null || body.isEmpty) return;

    final editing = _editingCommentId;
    if (editing != null) {
      _updateComment(editing, body);

      return;
    }

    // Текст уезжает в ленту сразу и очищается только здесь: если отправка
    // сорвётся, он останется видимым в ленте и его можно повторить.
    _commentController.clear();
    _commentsNotifier.send(
      body,
      IssueUserDto(
        id: session.id,
        displayName: session.displayName,
        avatarUrl: session.avatarUrl,
      ),
    );
  }

  Future<void> _updateComment(String commentId, String body) async {
    try {
      await _commentsNotifier.edit(commentId, body);
      if (!mounted) return;

      _commentController.clear();
      setState(() => _editingCommentId = null);
    } on Object {
      if (mounted) {
        ref
            .read(toastControllerProvider.notifier)
            .error('Не удалось сохранить комментарий');
      }
    }
  }

  void _startEditingComment(CommentDto comment) {
    _commentController.text = comment.body;
    setState(() => _editingCommentId = comment.id);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _composerKey.currentState?.focus(),
    );
  }

  Future<void> _deleteComment(CommentDto comment) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Удалить комментарий?',
      description:
          'Текст исчезнет полностью и восстановить его будет нельзя. '
          'В истории задачи останется факт удаления, без текста.',
      confirmLabel: 'Удалить',
    );
    if (!confirmed || !mounted) return;

    try {
      await _commentsNotifier.remove(comment.id);
    } on Object {
      if (mounted) {
        ref
            .read(toastControllerProvider.notifier)
            .error('Не удалось удалить комментарий');
      }
    }
  }

  // --- Вложения -------------------------------------------------------------

  Future<void> _pickAndUpload() async {
    final file = await ref
        .read(filePickerProvider)
        .pickOne(accept: '*/*');
    if (file == null) return;

    await _uploadFiles([file]);
  }

  Future<void> _uploadFiles(List<PickedFile> files) async {
    if (files.isEmpty) return;

    await ref
        .read(issueAttachmentsProvider(widget.issueKey).notifier)
        .upload(files);
  }

  Future<void> _addLink() async {
    final link = await AddLinkDialog.show(context);
    if (link == null || !mounted) return;

    try {
      await _issueNotifier.addLink(url: link.url, title: link.title);
    } on Object {
      if (mounted) {
        ref
            .read(toastControllerProvider.notifier)
            .error('Не удалось добавить ссылку');
      }
    }
  }

  // --- Якорь на комментарий -------------------------------------------------

  /// Прокручивает к комментарию из `?comment=<id>` и переводит на него фокус.
  ///
  /// Подсветка цветом — половина сигнала: человеку, не видящему экрана, нужен
  /// именно фокус (`screens/issue.md`, «Доступность»).
  Future<void> _resolveAnchor(CommentsPage page) async {
    final anchor = widget.anchorCommentId;
    if (anchor == null || _anchorResolved) return;

    final found = page.items.any((item) => item.id == anchor);
    if (!found) {
      // Комментарий может лежать выше — тогда его надо догрузить, но
      // не бесконечно: у задачи с тысячей комментариев поиск якоря выкачал
      // бы всю ленту. Если подгружать больше нечего или попытки кончились,
      // считаем комментарий удалённым (US-102): «нет доступа» здесь
      // невозможно, задача уже открыта.
      if (page.hasEarlier &&
          _anchorAttempts < IssueScreen.anchorLookupPages) {
        _anchorAttempts++;
        await _commentsNotifier.loadEarlier();

        return;
      }

      _anchorResolved = true;
      if (mounted) {
        ref
            .read(toastControllerProvider.notifier)
            .show('Комментарий удалён', variant: SLToastVariant.info);
      }

      return;
    }

    _anchorResolved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final key = _commentKeys[anchor];
      final target = key?.currentContext;
      if (target == null || !mounted) return;

      await Scrollable.ensureVisible(
        target,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
      );
      if (!mounted) return;

      Future<void>.delayed(CommentItem.highlightDuration, () {
        if (mounted) setState(() => _highlightedCommentId = null);
      });
    });
  }

  // --- Клавиатура -----------------------------------------------------------

  /// Набирает ли человек текст прямо сейчас.
  ///
  /// Хоткеи экрана — одиночные буквы, и без этой проверки буква «s»,
  /// набранная в комментарии, открывала бы меню статуса. `Shortcuts` стоит
  /// выше поля ввода в дереве и события до него доходят, поэтому решение
  /// принимаем сами: если фокус внутри поля ввода, хоткей не наш.
  static bool get _isTyping {
    final context = FocusManager.instance.primaryFocus?.context;

    return context != null &&
        context.findAncestorStateOfType<EditableTextState>() != null;
  }

  /// Оборачивает хоткей проверкой на ввод текста.
  VoidCallback _hotkey(VoidCallback action) => () {
    if (_isTyping) return;

    action();
  };

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.keyS): _hotkey(
      () => _statusFieldKey.currentState?.open(),
    ),
    const SingleActivator(LogicalKeyboardKey.keyA): _hotkey(
      () => _assigneeFieldKey.currentState?.open(),
    ),
    const SingleActivator(LogicalKeyboardKey.keyI): _hotkey(_assignToMe),
    const SingleActivator(LogicalKeyboardKey.keyE): _hotkey(
      _startEditingDescription,
    ),
    const SingleActivator(LogicalKeyboardKey.keyM): _hotkey(() {
      setState(() => _tab = IssueTab.comments);
      // Поле может быть свёрнуто: сначала разворачиваем, потом фокус.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _composerKey.currentState?.focus(),
      );
    }),
    const SingleActivator(LogicalKeyboardKey.keyY): _hotkey(_copyKey),
    const SingleActivator(LogicalKeyboardKey.keyY, shift: true): _hotkey(
      _copyLink,
    ),
  };

  // --- Раскладка ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final issue = ref.watch(issueProvider(widget.issueKey));
    final breakpoint = SLBreakpoint.of(context);

    // Подписка на тему задачи живёт, пока открыт экран: `watch` держит
    // провайдер, а он — подписку на сервере.
    final live = ref.watch(issueRealtimeProvider(widget.issueKey));

    // Удаление приходит один раз, и реагировать на него надо один раз —
    // поэтому слушателем, а не проверкой значения в `build`.
    ref.listen(
      issueRealtimeProvider(widget.issueKey).select((state) => state.deleted),
      (previous, deleted) {
        if (deleted && previous != true) _onDeletedElsewhere();
      },
    );

    final failure = issue.error == null ? null : ApiFailure.of(issue.error!);
    if (failure != null) return _buildError(failure);

    // Хоткеи живут на уровне экрана, но не перебивают ввод: `Shortcuts`
    // не срабатывает, пока фокус внутри текстового поля.
    // `Material`, а не `ColoredBox`: на экране есть `InkWell` — крошки,
    // поля панели, строки меню, — и им нужна материальная подложка.
    // Оболочка приложения её даёт, но экран не должен зависеть от того,
    // куда его вставили.
    return Material(
      color: colors.surface,
      child: CallbackShortcuts(
        bindings: _shortcuts,
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              if (breakpoint.isDesktop)
                _buildDesktop(issue.value)
              else
                _buildNarrow(issue.value, breakpoint),
              // Плашка не двигает ленту сама: человек решает, когда
              // спуститься к новому (`screens/README.md`, 7).
              if (live.newComments > 0 && _tab == IssueTab.comments)
                _NewCommentsPill(
                  count: live.newComments,
                  onPressed: _scrollToNewComments,
                ),
              if (_dropActive) const _DropOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ApiFailure failure) {
    // «Не найдена» и «нет доступа» снаружи неразличимы намеренно: иначе
    // экран подтверждал бы существование чужой задачи (US-41).
    if (failure.kind == ApiFailureKind.notFound ||
        failure.kind == ApiFailureKind.forbidden) {
      return SLErrorState(
        title: 'Задача не найдена',
        description:
            'Возможно, она удалена, или у вас нет доступа к её проекту.',
        actionLabel: 'К списку проектов',
        onAction: () => context.go(AppRoutes.projects),
      );
    }

    return SLErrorState(
      title: 'Не удалось загрузить задачу',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      onAction: _issueNotifier.refresh,
      details: failure.toString(),
    );
  }

  /// `lg` и `xl`: содержимое слева, залипающая панель полей справа.
  Widget _buildDesktop(IssueDto? issue) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: _buildContent(issue, showFieldsInline: false)),
      Container(
        width: SLSizes.issuePanelWidth,
        decoration: BoxDecoration(
          color: SLColorScheme.of(context).surface,
          border: Border(
            left: BorderSide(
              color: SLColorScheme.of(context).border,
              width: SLBorders.hairline,
            ),
          ),
        ),
        // Панель прокручивается отдельно и только если сама не помещается:
        // статус и исполнитель должны быть под рукой в любой момент чтения.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SLSpacing.space4),
          child: issue == null
              ? const IssueFieldsPanelLoading()
              : IssueFieldsPanel(
                  issue: issue,
                  statuses: _statuses(issue),
                  actions: _fieldsActions,
                  currentUserId: _currentUserId,
                  statusFieldKey: _statusFieldKey,
                  assigneeFieldKey: _assigneeFieldKey,
                ),
        ),
      ),
    ],
  );

  /// `md` и `sm`: панель полей уезжает наверх, под название.
  Widget _buildNarrow(IssueDto? issue, SLBreakpoint breakpoint) =>
      _buildContent(issue, showFieldsInline: true, breakpoint: breakpoint);

  List<IssueStatusRef> _statuses(IssueDto issue) =>
      ref.watch(queueStatusesProvider(issue.queue.key)).value ?? const [];

  Widget _buildContent(
    IssueDto? issue, {
    required bool showFieldsInline,
    SLBreakpoint? breakpoint,
  }) {
    final canEdit = issue?.permissions.canEdit ?? false;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: IssueScreen.contentMaxWidth,
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SLSpacing.space4,
                SLSpacing.space4,
                SLSpacing.space4,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IssueHeaderBar(
                      issueKey: widget.issueKey,
                      issue: issue,
                      onCopyKey: _copyKey,
                      onCopyLink: _copyLink,
                      onDelete:
                          (issue?.permissions.canDelete ?? false)
                          ? _deleteIssue
                          : null,
                    ),
                    const SizedBox(height: SLSpacing.space2),
                    if (issue == null)
                      const IssueHeaderSkeleton()
                    else
                      IssueTitle(
                        title: issue.title,
                        canEdit: canEdit,
                        onChanged: (value) => _edit(
                          () => _issueNotifier.changeTitle(value),
                          'Не удалось изменить название',
                        ),
                      ),
                    if (showFieldsInline && issue != null) ...[
                      const SizedBox(height: SLSpacing.space4),
                      if (breakpoint == SLBreakpoint.md)
                        IssueFieldsBand(
                          issue: issue,
                          statuses: _statuses(issue),
                          actions: _fieldsActions,
                          statusFieldKey: _statusFieldKey,
                          assigneeFieldKey: _assigneeFieldKey,
                        )
                      else
                        IssueFieldsCompact(
                          issue: issue,
                          statuses: _statuses(issue),
                          actions: _fieldsActions,
                          currentUserId: _currentUserId,
                          statusFieldKey: _statusFieldKey,
                          assigneeFieldKey: _assigneeFieldKey,
                        ),
                    ],
                    const SizedBox(height: SLSpacing.space6),
                    if (issue == null)
                      const DescriptionSkeleton()
                    else ...[
                      IssueDescription(
                        issueKey: widget.issueKey,
                        description: issue.description,
                        isEditing: _editingDescription,
                        isSaving: _savingDescription,
                        controller: _descriptionController,
                        canEdit: canEdit,
                        onStartEditing: _startEditingDescription,
                        onCancel: () =>
                            setState(() => _editingDescription = false),
                        onSave: _saveDescription,
                        onOpenLink: _openLink,
                        onOpenImage: (url) => ImageViewerDialog.show(
                          context,
                          url: url,
                          fileName: url,
                        ),
                      ),
                      if (canEdit && !_editingDescription)
                        _ActionsRow(
                          onAttach: _pickAndUpload,
                          onAddLink: _addLink,
                        ),
                      IssueAttachments(
                        issueKey: widget.issueKey,
                        onOpenImage: (attachment) => ImageViewerDialog.show(
                          context,
                          url: attachment.url,
                          fileName: attachment.fileName,
                        ),
                        onDownload: (attachment) => ref
                            .read(browserNavigatorProvider)
                            .openInNewTab(attachment.downloadUrl),
                      ),
                      IssueLinks(
                        links: issue.links,
                        canEdit: canEdit,
                        onAdd: _addLink,
                        onRemove: (id) => _edit(
                          () => _issueNotifier.removeLink(id),
                          'Не удалось удалить ссылку',
                        ),
                        onOpen: _openLink,
                      ),
                    ],
                    const SizedBox(height: SLSpacing.space6),
                    _StaleDataBanner(onRefresh: _refreshAll),
                    _Tabs(
                      value: _tab,
                      issueKey: widget.issueKey,
                      onChanged: (value) => setState(() => _tab = value),
                    ),
                    const SizedBox(height: SLSpacing.space4),
                    if (_tab == IssueTab.comments)
                      EarlierCommentsButton(issueKey: widget.issueKey),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: SLSpacing.space4,
              ),
              sliver: _tab == IssueTab.comments
                  ? _buildComments()
                  : HistorySliver(issueKey: widget.issueKey),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SLSpacing.space4,
                0,
                SLSpacing.space4,
                SLSpacing.space8,
              ),
              sliver: SliverToBoxAdapter(child: _buildComposer()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments() {
    // Якорь разбирается здесь, а не в `initState`: комментарии к этому
    // моменту ещё не загружены.
    final page = ref.watch(issueCommentsProvider(widget.issueKey)).value;
    if (page != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resolveAnchor(page),
      );
    }

    return CommentsSliver(
      issueKey: widget.issueKey,
      itemKeys: _commentKeys,
      highlightedCommentId: _highlightedCommentId,
      onOpenLink: _openLink,
      onOpenImage: (url) =>
          ImageViewerDialog.show(context, url: url, fileName: url),
      onEdit: _startEditingComment,
      onDelete: _deleteComment,
    );
  }

  Widget _buildComposer() {
    if (_tab != IssueTab.comments) return const SizedBox.shrink();

    final page = ref.watch(issueCommentsProvider(widget.issueKey)).value;
    if (page == null) return const SizedBox.shrink();
    if (!page.canComment) return const CommentComposerDenied();

    final session = ref.watch(sessionControllerProvider).user;
    if (session == null) return const SizedBox.shrink();

    return CommentComposer(
      key: _composerKey,
      controller: _commentController,
      focusNode: _composerFocus,
      issueKey: widget.issueKey,
      currentUserId: session.id,
      currentUserName: session.displayName,
      currentUserAvatarUrl: session.avatarUrl,
      submitLabel: _editingCommentId == null ? 'Отправить' : 'Сохранить',
      startExpanded: _editingCommentId != null,
      onSubmit: _sendComment,
      onCancel: _editingCommentId == null
          ? null
          : () {
              _commentController.clear();
              setState(() => _editingCommentId = null);
            },
    );
  }
}

/// Строка действий под описанием.
///
/// Здесь живут «Прикрепить» и «Добавить ссылку», когда блоков вложений
/// и ссылок нет вовсе: иначе у человека возникнет впечатление, что
/// прикрепить файл нельзя (US-48, Q-D19).
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.onAttach, required this.onAddLink});

  final VoidCallback onAttach;
  final VoidCallback onAddLink;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: SLSpacing.space3),
    // `Wrap`: на узком экране кнопки переносятся, а не уезжают за край.
    child: Wrap(
      spacing: SLSpacing.space2,
      runSpacing: SLSpacing.space1,
      children: [
        SLButton(
          label: 'Прикрепить',
          icon: Icons.attach_file_rounded,
          variant: SLButtonVariant.ghost,
          size: SLButtonSize.sm,
          onPressed: onAttach,
        ),
        SLButton(
          label: 'Добавить ссылку',
          icon: Icons.link_rounded,
          variant: SLButtonVariant.ghost,
          size: SLButtonSize.sm,
          onPressed: onAddLink,
        ),
      ],
    ),
  );
}

/// Вкладки «Комментарии» и «История».
///
/// У «Истории» счётчика нет намеренно: число записей журнала ничего
/// не значит. Вместо него точка `accent`, когда за последний час что-то
/// меняли.
class _Tabs extends ConsumerWidget {
  const _Tabs({
    required this.value,
    required this.issueKey,
    required this.onChanged,
  });

  final IssueTab value;
  final String issueKey;
  final ValueChanged<IssueTab> onChanged;

  /// Диаметр точки «есть свежие изменения».
  static const dotSize = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = SLColorScheme.of(context);
    final comments = ref.watch(issueCommentsProvider(issueKey)).value;
    final history = ref.watch(issueHistoryProvider(issueKey)).value;
    final hasRecent = history?.hasRecentChanges() ?? false;

    return Row(
      children: [
        Expanded(
          child: SLTabBar<IssueTab>(
            value: value,
            onChanged: onChanged,
            tabs: [
              SLTabItem(
                value: IssueTab.comments,
                label: 'Комментарии',
                count: comments?.total ?? SLTabItem.loading,
              ),
              const SLTabItem(value: IssueTab.history, label: 'История'),
            ],
          ),
        ),
        if (hasRecent)
          Semantics(
            label: 'История, есть недавние изменения',
            child: Container(
              width: dotSize,
              height: dotSize,
              margin: const EdgeInsets.only(left: SLSpacing.space1),
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// Зона сброса файлов поверх содержимого.
class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  /// Толщина пунктирной границы.
  static const borderWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: colors.accentSurface.withValues(alpha: 0.9),
            border: Border.all(color: colors.accent, width: borderWidth),
            borderRadius: SLRadii.mdAll,
          ),
          alignment: Alignment.center,
          child: Text(
            'Отпустите файлы, чтобы прикрепить',
            style: text.title.copyWith(color: colors.accentPressed),
          ),
        ),
      ),
    );
  }
}

/// Баннер «данные могут быть устаревшими».
///
/// Показывается, пока живой связи нет: полоса офлайна в шапке говорит
/// о соединении вообще, а этот баннер — о том, что именно эта лента
/// перестала обновляться сама (`screens/issue.md`, «Нет соединения»).
class _StaleDataBanner extends ConsumerWidget {
  const _StaleDataBanner({required this.onRefresh});

  /// Перечитать данные экрана обычными запросами.
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(
      realtimeStatusProvider.select(
        (status) => status == RealtimeStatus.offline,
      ),
    );
    if (!offline) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space3),
      child: SLBanner(
        title: 'Данные могут быть устаревшими',
        description: 'Связь потеряна — новые комментарии и правки не приедут.',
        variant: SLBannerVariant.warning,
        actionLabel: 'Обновить',
        onAction: onRefresh,
      ),
    );
  }
}

/// Плашка «Новых комментариев: N».
///
/// Появляется, только когда человек не внизу ленты: если он там, новое
/// и так видно, а плашка закрывала бы поле ввода.
class _NewCommentsPill extends StatelessWidget {
  const _NewCommentsPill({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Positioned(
      left: 0,
      right: 0,
      bottom: SLSpacing.space6,
      child: Center(
        child: Semantics(
          button: true,
          liveRegion: true,
          label: 'Новых комментариев: $count. Показать',
          child: ExcludeSemantics(
            child: Material(
              color: colors.accent,
              borderRadius: SLRadii.fullAll,
              child: InkWell(
                onTap: onPressed,
                borderRadius: SLRadii.fullAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SLSpacing.space3,
                    vertical: SLSpacing.space2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: SLIconSizes.icon16,
                        color: colors.textOnAccent,
                      ),
                      const SizedBox(width: SLSpacing.space1),
                      Text(
                        'Новых комментариев: $count',
                        style: text.bodySStrong.copyWith(
                          color: colors.textOnAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
