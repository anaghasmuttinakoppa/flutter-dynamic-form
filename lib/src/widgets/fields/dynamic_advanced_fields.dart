import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';

/// Slider / range slider / rating / color fields.
class DynamicSliderField extends StatelessWidget {
  /// Creates a [DynamicSliderField].
  const DynamicSliderField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final enabled = controller.isFieldEnabled(field);
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);
    final min = (field.min ?? 0).toDouble();
    final max = (field.max ?? 100).toDouble();
    final raw = controller.getValue(field.key);
    final value = (raw is num ? raw.toDouble() : min).clamp(min, max);

    return Semantics(
      label: field.effectiveSemanticLabel,
      slider: true,
      enabled: enabled,
      value: value.toStringAsFixed(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.effectiveLabel,
                  style: resolved.labelStyle ?? material.textTheme.titleSmall,
                ),
              ),
              Text(value.toStringAsFixed(field.divisions != null ? 0 : 1)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: field.divisions,
            label: value.toStringAsFixed(0),
            onChanged: enabled
                ? (v) => controller.updateField(field.key, v, validate: false)
                : null,
            onChangeEnd: enabled
                ? (v) => controller.updateField(field.key, v)
                : null,
          ),
          if (error != null)
            Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: material.colorScheme.error),
            ),
        ],
      ),
    );
  }
}

/// Range slider field.
class DynamicRangeSliderField extends StatelessWidget {
  /// Creates a [DynamicRangeSliderField].
  const DynamicRangeSliderField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final enabled = controller.isFieldEnabled(field);
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);
    final min = (field.min ?? 0).toDouble();
    final max = (field.max ?? 100).toDouble();
    final raw = controller.getValue(field.key);
    RangeValues values;
    if (raw is List && raw.length >= 2) {
      values = RangeValues(
        (raw[0] as num).toDouble().clamp(min, max),
        (raw[1] as num).toDouble().clamp(min, max),
      );
    } else {
      values = RangeValues(min, max);
    }

    return Semantics(
      label: field.effectiveSemanticLabel,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${field.effectiveLabel} '
            '(${values.start.toStringAsFixed(0)} – ${values.end.toStringAsFixed(0)})',
            style: resolved.labelStyle ?? material.textTheme.titleSmall,
          ),
          RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: field.divisions,
            labels: RangeLabels(
              values.start.toStringAsFixed(0),
              values.end.toStringAsFixed(0),
            ),
            onChanged: enabled
                ? (v) => controller.updateField(
                      field.key,
                      <num>[v.start, v.end],
                      validate: false,
                    )
                : null,
            onChangeEnd: enabled
                ? (v) => controller.updateField(
                      field.key,
                      <num>[v.start, v.end],
                    )
                : null,
          ),
          if (error != null)
            Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: material.colorScheme.error),
            ),
        ],
      ),
    );
  }
}

/// Star rating field.
class DynamicRatingField extends StatelessWidget {
  /// Creates a [DynamicRatingField].
  const DynamicRatingField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final enabled = controller.isFieldEnabled(field);
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);
    final maxStars = (field.max ?? 5).toInt();
    final raw = controller.getValue(field.key);
    final rating = raw is num ? raw.toInt() : 0;

    return Semantics(
      label: field.effectiveSemanticLabel,
      enabled: enabled,
      value: '$rating of $maxStars',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            field.effectiveLabel,
            style: resolved.labelStyle ?? material.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(maxStars, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: enabled
                    ? () => controller.updateField(field.key, star)
                    : null,
                icon: Icon(
                  star <= rating ? Icons.star : Icons.star_border,
                  color: material.colorScheme.primary,
                ),
                tooltip: '$star',
              );
            }),
          ),
          if (error != null)
            Text(
              error,
              style: resolved.errorStyle ??
                  TextStyle(color: material.colorScheme.error),
            ),
        ],
      ),
    );
  }
}

/// Simple color swatch picker.
class DynamicColorField extends StatelessWidget {
  /// Creates a [DynamicColorField].
  const DynamicColorField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  static const _palette = <String>[
    '#F44336',
    '#E91E63',
    '#9C27B0',
    '#673AB7',
    '#3F51B5',
    '#2196F3',
    '#03A9F4',
    '#00BCD4',
    '#009688',
    '#4CAF50',
    '#8BC34A',
    '#CDDC39',
    '#FFEB3B',
    '#FFC107',
    '#FF9800',
    '#FF5722',
    '#795548',
    '#607D8B',
    '#000000',
    '#FFFFFF',
  ];

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final enabled = controller.isFieldEnabled(field);
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);
    final current = (controller.getValue(field.key) as String?) ?? '#2196F3';

    final colors = field.options.isNotEmpty
        ? field.options.map((o) => o.value.toString()).toList()
        : _palette;

    return Semantics(
      label: field.effectiveSemanticLabel,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${field.effectiveLabel} ($current)',
            style: resolved.labelStyle ?? material.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((hex) {
              final selected = hex.toUpperCase() == current.toUpperCase();
              return InkWell(
                onTap: enabled
                    ? () => controller.updateField(field.key, hex)
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parseColor(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? material.colorScheme.primary
                          : material.dividerColor,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: resolved.errorStyle ??
                    TextStyle(color: material.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    var cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    return Color(int.parse(cleaned, radix: 16));
  }
}
