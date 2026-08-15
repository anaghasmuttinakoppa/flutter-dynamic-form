import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../core/enums.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';
import '../../utils/date_time_utils.dart';

/// Date / time / dateTime picker field.
class DynamicDateTimeField extends StatelessWidget {
  /// Creates a [DynamicDateTimeField].
  const DynamicDateTimeField({
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
    final error = controller.errorFor(field.key);
    final value = controller.getValue(field.key);

    final display = switch (field.type) {
      FieldType.time => DateTimeUtils.display(
          value,
          format: field.dateFormat ?? 'HH:mm',
          timeOnly: true,
        ),
      FieldType.date => DateTimeUtils.display(
          value,
          format: field.dateFormat ?? 'yyyy-MM-dd',
        ),
      _ => DateTimeUtils.display(
          value,
          format: field.dateFormat ?? 'yyyy-MM-dd HH:mm',
        ),
    };

    final icon = switch (field.type) {
      FieldType.time => Icons.schedule_outlined,
      FieldType.date => Icons.calendar_today_outlined,
      _ => Icons.event_outlined,
    };

    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      borderRadius: BorderRadius.circular(resolved.borderRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.effectivePlaceholder ?? _hint(),
          helperText: error == null ? field.helperText : null,
          errorText: error,
          errorStyle: resolved.errorStyle,
          helperStyle: resolved.helperStyle,
          labelStyle: resolved.labelStyle,
          filled: true,
          isDense: resolved.dense,
          contentPadding: resolved.contentPadding,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(resolved.borderRadius),
          ),
          enabled: enabled,
        ),
        child: Text(
          display.isEmpty ? (field.effectivePlaceholder ?? _hint()) : display,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: display.isEmpty
                    ? Theme.of(context).hintColor
                    : null,
              ),
        ),
      ),
    );
  }

  String _hint() {
    return switch (field.type) {
      FieldType.time => 'Select time',
      FieldType.date => 'Select date',
      _ => 'Select date & time',
    };
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();

    if (field.type == FieldType.time) {
      final existing = DateTimeUtils.tryParseTime(controller.getValue(field.key));
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: existing?.hour ?? now.hour,
          minute: existing?.minute ?? now.minute,
        ),
      );
      if (picked == null) return;
      controller.updateField(
        field.key,
        DateTimeUtils.formatTime(picked.hour, picked.minute),
      );
      return;
    }

    final existingDt =
        DateTimeUtils.tryParse(controller.getValue(field.key)) ?? now;
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year + 50);

    final date = await showDatePicker(
      context: context,
      initialDate: existingDt,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null) return;

    if (field.type == FieldType.date) {
      controller.updateField(field.key, DateTimeUtils.formatDate(date));
      return;
    }

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: existingDt.hour, minute: existingDt.minute),
    );
    if (time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    controller.updateField(field.key, DateTimeUtils.formatDateTime(combined));
  }
}
