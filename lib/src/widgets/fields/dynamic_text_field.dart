import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../core/enums.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';
import '../../utils/field_utils.dart';

/// Renders Phase 1 text-based fields (text, email, password, number, phone,
/// multiline) bound to a [DynamicFormController].
class DynamicTextField extends StatefulWidget {
  /// Creates a [DynamicTextField].
  const DynamicTextField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Optional theme override.
  final DynamicFormTheme? theme;

  @override
  State<DynamicTextField> createState() => _DynamicTextFieldState();
}

class _DynamicTextFieldState extends State<DynamicTextField> {
  late final TextEditingController _textController;
  late bool _obscure;

  FormFieldSchema get field => widget.field;
  DynamicFormController get formController => widget.controller;

  @override
  void initState() {
    super.initState();
    _obscure = field.obscureText || field.type == FieldType.password;
    _textController = TextEditingController(
      text: FieldUtils.valueToText(formController.getValue(field.key)),
    );
    formController.addListener(_onFormChanged);
  }

  @override
  void didUpdateWidget(covariant DynamicTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onFormChanged);
      widget.controller.addListener(_onFormChanged);
      _syncFromController();
    }
  }

  void _onFormChanged() {
    final current = FieldUtils.valueToText(formController.getValue(field.key));
    if (_textController.text != current) {
      _textController.value = TextEditingValue(
        text: current,
        selection: TextSelection.collapsed(offset: current.length),
      );
    }
    if (mounted) setState(() {});
  }

  void _syncFromController() {
    final current = FieldUtils.valueToText(formController.getValue(field.key));
    _textController.text = current;
  }

  @override
  void dispose() {
    formController.removeListener(_onFormChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? DynamicFormThemeProvider.of(context);
    final materialTheme = Theme.of(context);
    final errorText = formController.errorFor(field.key);
    final isPassword = field.type == FieldType.password || field.obscureText;
    final enabled = formController.isFieldEnabled(field);

    final prefixIconData = FieldUtils.resolveIcon(field.prefixIcon) ??
        _defaultPrefixIcon(field.type);
    final suffixIconData = FieldUtils.resolveIcon(field.suffixIcon);

    final decoration = InputDecoration(
      labelText: field.label,
      hintText: field.effectivePlaceholder,
      helperText: field.helperText,
      errorText: errorText,
      errorStyle: theme.errorStyle,
      helperStyle: theme.helperStyle,
      labelStyle: theme.labelStyle,
      filled: true,
      isDense: theme.dense,
      contentPadding: theme.contentPadding,
      prefixIcon: prefixIconData != null ? Icon(prefixIconData) : null,
      suffixIcon: isPassword
          ? IconButton(
              tooltip: _obscure ? 'Show' : 'Hide',
              onPressed: enabled
                  ? () => setState(() => _obscure = !_obscure)
                  : null,
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            )
          : (suffixIconData != null ? Icon(suffixIconData) : null),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
    );

    final maxLines = field.type == FieldType.multiline
        ? (field.maxLines ?? 4)
        : (field.maxLines ?? 1);
    final minLines = field.type == FieldType.multiline
        ? (field.minLines ?? 3)
        : field.minLines;

    return TextField(
      controller: _textController,
      enabled: enabled,
      readOnly: field.readOnly,
      obscureText: _obscure && isPassword,
      keyboardType: FieldUtils.resolveKeyboardType(field),
      inputFormatters: FieldUtils.resolveFormatters(field),
      minLines: minLines,
      maxLines: maxLines,
      style: materialTheme.textTheme.bodyLarge,
      decoration: decoration,
      onChanged: (text) {
        final value = FieldUtils.parseValue(field, text);
        formController.updateField(field.key, value);
      },
      onEditingComplete: () {
        formController.validateField(field.key);
      },
    );
  }

  IconData? _defaultPrefixIcon(FieldType type) {
    switch (type) {
      case FieldType.email:
        return Icons.email_outlined;
      case FieldType.password:
        return Icons.lock_outline;
      case FieldType.phone:
        return Icons.phone_outlined;
      case FieldType.number:
        return Icons.tag;
      case FieldType.multiline:
        return Icons.notes_outlined;
      case FieldType.text:
        return Icons.person_outline;
      case FieldType.checkbox:
      case FieldType.switchField:
      case FieldType.radio:
      case FieldType.dropdown:
      case FieldType.chips:
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
      case FieldType.group:
      case FieldType.repeatable:
      case FieldType.image:
      case FieldType.file:
      case FieldType.camera:
      case FieldType.location:
      case FieldType.slider:
      case FieldType.rangeSlider:
      case FieldType.rating:
      case FieldType.signature:
      case FieldType.color:
      case FieldType.custom:
      case FieldType.unknown:
        return null;
    }
  }
}
