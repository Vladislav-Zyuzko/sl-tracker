import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/projects/domain/project_slug.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Секция «Короткое имя в адресе» вкладки настроек (US-18).
///
/// Ввод приводится к допустимому виду **на лету**: человек печатает
/// «Сладкий Лимит» — в поле появляется `sladkiy-limit`. Молчаливое
/// отбрасывание символов запрещено, поэтому под полем всегда написано,
/// что именно разрешено.
///
/// Итоговое значение всегда берётся из ответа сервера: правило
/// транслитерации одно на клиент и сервер, но занятость имени знает
/// только сервер.
///
/// Слово «слаг» в интерфейсе не появляется (`glossary.md`).
class ProjectSlugSection extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectSlugSection({
    required this.project,
    required this.onChanged,
    super.key,
  });

  /// Проект.
  final ProjectDto project;

  /// Короткое имя изменилось: экран заменяет адрес в строке браузера.
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<ProjectSlugSection> createState() => _ProjectSlugSectionState();
}

class _ProjectSlugSectionState extends ConsumerState<ProjectSlugSection> {
  late final TextEditingController _controller;

  String? _error;
  ApiFailure? _failure;
  var _value = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.project.slug;
    _controller = TextEditingController(text: _value);
  }

  @override
  void didUpdateWidget(ProjectSlugSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Имя сменилось (нашим же действием или снаружи) — поле подхватывает
    // действующее значение с сервера, а не то, что человек набрал.
    if (oldWidget.project.slug == widget.project.slug) return;

    _value = widget.project.slug;
    _controller.text = _value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Значение отличается от сохранённого.
  bool get _isChanged => _value != widget.project.slug;

  /// Приведение к допустимому виду видно сразу: иначе оно станет сюрпризом
  /// после отправки.
  void _onChanged(String raw) {
    final normalized = ProjectSlug.normalizeInput(raw);

    if (normalized != raw) {
      _controller.value = _controller.value.copyWith(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
        composing: TextRange.empty,
      );
    }

    setState(() {
      _value = normalized;
      _error = null;
      _failure = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_isChanged) return;

    final problem = ProjectSlug.validate(_value);
    if (problem != null) {
      setState(() => _error = _textOfCode(problem));

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _failure = null;
    });

    try {
      final updated = await ref
          .read(projectProvider(widget.project.slug).notifier)
          .changeSlug(_value);

      if (!mounted) return;
      setState(() {
        _saving = false;
        // Из ответа, а не из поля: сервер — источник правды.
        _value = updated.slug;
        _controller.text = updated.slug;
      });

      widget.onChanged(updated.slug);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        final code = failure.code ?? '';
        if (code == 'slug_taken' ||
            code == 'reserved_slug' ||
            code == 'invalid_slug') {
          _error = _textOfCode(code);
        } else {
          _failure = failure;
        }
      });
    }
  }

  /// Тексты одни и те же, проверил ли клиент или ответил сервер.
  ///
  /// «Занято» не говорит, каким проектом: чужой проект не должен
  /// подтверждаться даже так (`permissions.md`, п. 5).
  static String _textOfCode(String code) => switch (code) {
    'slug_taken' => 'Такой адрес уже занят',
    'reserved_slug' => 'Этот адрес зарезервирован приложением',
    _ => 'Только строчные латинские буквы, цифры и дефис',
  };

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final origin = ref.read(browserNavigatorProvider).origin;
    final failure = _failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SLTextField(
          controller: _controller,
          errorText: _error,
          helper: 'Только строчные латинские буквы, цифры и дефис',
          readOnly: _saving,
          maxLength: ProjectSlug.maxLength,
          onChanged: _onChanged,
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: SLSpacing.space2),
        Text(
          'Адрес проекта будет:',
          style: text.label.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: SLSpacing.space1),
        SelectionArea(
          child: Text(
            '$origin${AppRoutes.projectPath(_value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.mono.copyWith(color: colors.textSecondary),
          ),
        ),
        // Предупреждение показывается только когда значение изменено —
        // постоянное предупреждение перестают читать.
        if (_isChanged) ...[
          const SizedBox(height: SLSpacing.space3),
          const SLBanner(
            title: 'Адрес изменится',
            description:
                'Ранее отправленные ссылки продолжат открывать проект, '
                'но в браузере будет показываться новый адрес.',
            variant: SLBannerVariant.warning,
          ),
        ],
        if (failure != null) ...[
          const SizedBox(height: SLSpacing.space3),
          SLBanner(
            title: 'Не удалось изменить адрес',
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
            label: 'Изменить адрес',
            isLoading: _saving,
            onPressed: _isChanged ? _save : null,
          ),
        ),
      ],
    );
  }
}
