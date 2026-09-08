import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/domain/project_limits.dart';
import 'package:sl_tracker_web/features/projects/domain/project_slug.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_list_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Создание проекта (`docs/design/screens/projects.md`).
///
/// Возвращает созданный проект или `null`, если человек передумал.
///
/// Обязательное поле одно — название. Обложка при создании не загружается:
/// это лишний шаг в самом первом действии пользователя, она добавляется
/// потом, в настройках проекта (US-12).
class CreateProjectDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const CreateProjectDialog({super.key});

  /// Показывает окно.
  static Future<ProjectDto?> show(BuildContext context) =>
      showDialog<ProjectDto>(
        context: context,
        builder: (context) => const CreateProjectDialog(),
      );

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'project-name');

  String? _nameError;
  ApiFailure? _failure;
  var _name = '';
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    // Ошибка у поля — по потере фокуса, а не по каждому символу: подчёркивать
    // «пусто» в поле, которое человек ещё не заполнял, незачем.
    _nameFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _nameFocusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_nameFocusNode.hasFocus) return;

    setState(() => _nameError = _name.trim().isEmpty ? _emptyNameError : null);
  }

  static const _emptyNameError = 'Без названия проект не создать';

  void _onNameChanged(String value) => setState(() {
    _name = value;
    _nameError = null;
    _failure = null;
  });

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _name.trim();
    if (name.isEmpty) {
      // Запрос на сервер не уходит: пустое название — заведомо отказ (US-11).
      setState(() => _nameError = _emptyNameError);
      _nameFocusNode.requestFocus();

      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final created = await ref
          .read(projectsListProvider.notifier)
          .create(name: name, description: _descriptionController.text.trim());

      if (mounted) Navigator.of(context).pop(created);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        // Данные формы сохраняются: набирать название заново из-за ответа
        // сервера — издевательство.
        switch ((failure.kind, failure.code)) {
          case (ApiFailureKind.conflict, _):
            _nameError = 'Такой адрес уже занят, измените название';
          case (_, 'invalid_project_name'):
            _nameError = 'Сервер не принял это название';
          default:
            _failure = failure;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.trim();
    final preview = ProjectSlug.slugify(name);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: SLDialog(
        title: 'Создать проект',
        onClose: _submitting ? null : () => Navigator.of(context).pop(),
        banner: _failure == null
            ? null
            : SLBanner(
                title: 'Не удалось создать проект',
                description: 'Проверьте соединение и попробуйте ещё раз.',
                details: _failure!.toString(),
              ),
        actions: [
          SLButton(
            label: 'Отмена',
            variant: SLButtonVariant.secondary,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          SLButton(
            label: 'Создать',
            isLoading: _submitting,
            // Пустое название — кнопка отключена.
            onPressed: name.isEmpty ? null : _submit,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SLTextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Название *',
              errorText: _nameError,
              helper: ProjectLimits.shouldCountName(_name)
                  ? ProjectLimits.nameCounterText(_name)
                  : null,
              readOnly: _submitting,
              autofocus: true,
              maxLength: ProjectLimits.nameMaxLength,
              onChanged: _onNameChanged,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: SLSpacing.space3),
            _SlugPreview(slug: preview),
            const SizedBox(height: SLSpacing.space4),
            SLTextField.multiline(
              controller: _descriptionController,
              label: 'Описание',
              readOnly: _submitting,
              maxLength: ProjectLimits.descriptionMaxLength,
            ),
          ],
        ),
      ),
    );
  }
}

/// Предпросмотр адреса проекта.
///
/// Подписан «будет», а не «адрес проекта», и это не придирка к формулировке:
/// сервер может добавить суффикс из-за коллизии (`-2`), и тогда фактический
/// адрес разойдётся с показанным. Расхождение не пугает, если обещания
/// не было (D-35, Q-D9).
class _SlugPreview extends StatelessWidget {
  const _SlugPreview({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    // Из названия не вышло ни одного допустимого символа (название из эмодзи):
    // номер запасного имени знает только сервер.
    final isEmpty = slug.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Адрес проекта будет:',
          style: text.label.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: SLSpacing.space1),
        Text(
          isEmpty ? '/projects/project-…' : '/projects/$slug',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.mono.copyWith(color: colors.textSecondary),
        ),
        if (isEmpty) ...[
          const SizedBox(height: SLSpacing.space1),
          Text(
            'Адрес будет назначен автоматически.',
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}
