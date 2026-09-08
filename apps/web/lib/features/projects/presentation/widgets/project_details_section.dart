import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/domain/project_limits.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

/// Секция «Название и описание» вкладки настроек
/// (`docs/design/screens/project.md`).
///
/// Переименование **не меняет** короткое имя в адресе: ранее отправленные
/// ссылки продолжают работать (US-18). Адрес меняется отдельной секцией
/// и отдельным действием.
class ProjectDetailsSection extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectDetailsSection({required this.project, super.key});

  /// Проект.
  final ProjectDto project;

  @override
  ConsumerState<ProjectDetailsSection> createState() =>
      _ProjectDetailsSectionState();
}

class _ProjectDetailsSectionState extends ConsumerState<ProjectDetailsSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  String? _nameError;
  ApiFailure? _failure;
  var _saving = false;
  var _name = '';
  var _description = '';

  @override
  void initState() {
    super.initState();
    _name = widget.project.name;
    _description = widget.project.description ?? '';
    _nameController = TextEditingController(text: _name);
    _descriptionController = TextEditingController(text: _description);
  }

  @override
  void didUpdateWidget(ProjectDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Проект перечитали снаружи (например, после смены короткого имени):
    // подставляем свежие значения, но только если человек ничего не правил.
    if (oldWidget.project == widget.project || _hasChanges) return;

    _name = widget.project.name;
    _description = widget.project.description ?? '';
    _nameController.text = _name;
    _descriptionController.text = _description;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Кнопка «Сохранить» активна только при изменениях.
  bool get _hasChanges =>
      _name.trim() != widget.project.name ||
      _description.trim() != (widget.project.description ?? '').trim();

  Future<void> _save() async {
    if (_saving) return;

    final name = _name.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Без названия проект не сохранить');

      return;
    }

    setState(() {
      _saving = true;
      _failure = null;
      _nameError = null;
    });

    try {
      await ref
          .read(projectProvider(widget.project.slug).notifier)
          .updateDetails(name: name, description: _description.trim());

      if (!mounted) return;
      setState(() => _saving = false);
      ref.read(toastControllerProvider.notifier).success('Изменения сохранены');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SLTextField(
          controller: _nameController,
          label: 'Название',
          errorText: _nameError,
          helper: ProjectLimits.shouldCountName(_name)
              ? ProjectLimits.nameCounterText(_name)
              : null,
          readOnly: _saving,
          maxLength: ProjectLimits.nameMaxLength,
          onChanged: (value) => setState(() {
            _name = value;
            _nameError = null;
          }),
        ),
        const SizedBox(height: SLSpacing.space3),
        SLTextField.multiline(
          controller: _descriptionController,
          label: 'Описание',
          helper: 'Markdown, до 5000 символов',
          readOnly: _saving,
          maxLength: ProjectLimits.descriptionMaxLength,
          onChanged: (value) => setState(() => _description = value),
        ),
        if (failure != null) ...[
          const SizedBox(height: SLSpacing.space3),
          SLBanner(
            title: 'Не удалось сохранить',
            description: failure.kind == ApiFailureKind.forbidden
                ? 'Похоже, вашу роль в проекте изменили.'
                : 'Проверьте соединение и попробуйте ещё раз.',
            details: failure.toString(),
          ),
        ],
        const SizedBox(height: SLSpacing.space3),
        Align(
          alignment: Alignment.centerLeft,
          child: SLButton(
            label: 'Сохранить',
            isLoading: _saving,
            onPressed: _hasChanges ? _save : null,
          ),
        ),
      ],
    );
  }
}
