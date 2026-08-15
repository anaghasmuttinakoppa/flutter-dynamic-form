import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';

/// Checkbox field bound to a [DynamicFormController].
class DynamicCheckboxField extends StatelessWidget {
  /// Creates a [DynamicCheckboxField].
  const DynamicCheckboxField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Optional theme.
  final DynamicFormTheme? theme;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final enabled = controller.isFieldEnabled(field);
    final value = controller.getValue(field.key) == true;
    final error = controller.errorFor(field.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: value,
          dense: resolved.dense,
          enabled: enabled,
          contentPadding: EdgeInsets.zero,
          title: Text(field.effectiveLabel, style: resolved.labelStyle),
          subtitle: field.helperText != null && error == null
              ? Text(field.helperText!, style: resolved.helperStyle)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: enabled
              ? (v) => controller.updateField(field.key, v ?? false)
              : null,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// Switch field bound to a [DynamicFormController].
class DynamicSwitchField extends StatelessWidget {
  /// Creates a [DynamicSwitchField].
  const DynamicSwitchField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Optional theme.
  final DynamicFormTheme? theme;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final enabled = controller.isFieldEnabled(field);
    final value = controller.getValue(field.key) == true;
    final error = controller.errorFor(field.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: value,
          dense: resolved.dense,
          title: Text(field.effectiveLabel, style: resolved.labelStyle),
          subtitle: field.helperText != null && error == null
              ? Text(field.helperText!, style: resolved.helperStyle)
              : null,
          onChanged: enabled
              ? (v) => controller.updateField(field.key, v)
              : null,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
