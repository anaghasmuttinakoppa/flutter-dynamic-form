import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';

/// Radio group field.
class DynamicRadioField extends StatelessWidget {
  /// Creates a [DynamicRadioField].
  const DynamicRadioField({
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
    final current = controller.getValue(field.key);
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          field.effectiveLabel,
          style: resolved.labelStyle ?? material.textTheme.titleSmall,
        ),
        if (field.helperText != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(field.helperText!, style: resolved.helperStyle),
          ),
        RadioGroup<dynamic>(
          groupValue: current,
          onChanged: enabled
              ? (v) => controller.updateField(field.key, v)
              : (_) {},
          child: Column(
            children: field.options.map((option) {
              return RadioListTile<dynamic>(
                value: option.value,
                dense: resolved.dense,
                title: Text(option.label),
                enabled: enabled && option.enabled,
              );
            }).toList(),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: material.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// Dropdown select field.
class DynamicDropdownField extends StatelessWidget {
  /// Creates a [DynamicDropdownField].
  const DynamicDropdownField({
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
    final current = controller.getValue(field.key);
    final error = controller.errorFor(field.key);

    final items = field.options
        .where((o) => o.enabled)
        .map(
          (o) => DropdownMenuItem<dynamic>(
            value: o.value,
            child: Text(o.label),
          ),
        )
        .toList();

    // Ensure current value exists in items to avoid assertion.
    final hasValue = items.any((i) => i.value == current);

    return DropdownButtonFormField<dynamic>(
      initialValue: hasValue ? current : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.effectivePlaceholder,
        helperText: error == null ? field.helperText : null,
        errorText: error,
        errorStyle: resolved.errorStyle,
        helperStyle: resolved.helperStyle,
        labelStyle: resolved.labelStyle,
        filled: true,
        isDense: resolved.dense,
        contentPadding: resolved.contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(resolved.borderRadius),
        ),
      ),
      items: items,
      onChanged: enabled
          ? (v) => controller.updateField(field.key, v)
          : null,
    );
  }
}

/// Multi-select filter chips field.
class DynamicChipsField extends StatelessWidget {
  /// Creates a [DynamicChipsField].
  const DynamicChipsField({
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
    final raw = controller.getValue(field.key);
    final selected = raw is List ? List<dynamic>.from(raw) : <dynamic>[];
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          field.effectiveLabel,
          style: resolved.labelStyle ?? material.textTheme.titleSmall,
        ),
        if (field.helperText != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(field.helperText!, style: resolved.helperStyle),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: field.options.map((option) {
            final isSelected = selected.any((e) => e == option.value);
            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: enabled && option.enabled
                  ? (select) {
                      final next = List<dynamic>.from(selected);
                      if (select) {
                        if (!next.any((e) => e == option.value)) {
                          next.add(option.value);
                        }
                      } else {
                        next.removeWhere((e) => e == option.value);
                      }
                      controller.updateField(field.key, next);
                    }
                  : null,
            );
          }).toList(),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: material.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
