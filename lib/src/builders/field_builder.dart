import 'package:flutter/material.dart';

import '../controllers/dynamic_form_controller.dart';
import '../core/enums.dart';
import '../models/form_field_schema.dart';
import '../plugins/plugin_registry.dart';
import '../theme/dynamic_form_theme.dart';
import '../widgets/fields/dynamic_advanced_fields.dart';
import '../widgets/fields/dynamic_bool_fields.dart';
import '../widgets/fields/dynamic_datetime_field.dart';
import '../widgets/fields/dynamic_group_field.dart';
import '../widgets/fields/dynamic_media_fields.dart';
import '../widgets/fields/dynamic_repeatable_field.dart';
import '../widgets/fields/dynamic_selection_fields.dart';
import '../widgets/fields/dynamic_signature_field.dart';
import '../widgets/fields/dynamic_text_field.dart';
import '../widgets/fields/field_chrome.dart';

/// Builds concrete field widgets from [FormFieldSchema] definitions.
class FieldBuilder {
  /// Creates a [FieldBuilder].
  const FieldBuilder();

  /// Builds a widget for [field] bound to [controller].
  Widget build({
    required BuildContext context,
    required FormFieldSchema field,
    required DynamicFormController controller,
    DynamicFormTheme? theme,
  }) {
    final visible = controller.isFieldVisible(field);
    final resolvedTheme = theme ?? DynamicFormThemeProvider.of(context);
    final registry = DynamicFormPlugins.maybeOf(context);

    // Plugin / custom renderer override (by customType or raw type name).
    final typeName = field.customType ??
        (field.type == FieldType.custom ? field.extra['type'] as String? : null);
    if (typeName != null && registry != null) {
      final renderer = registry.rendererFor(typeName);
      if (renderer != null) {
        final custom = renderer(
          FieldRenderContext(
            context: context,
            field: field,
            controller: controller,
            theme: resolvedTheme,
          ),
        );
        return _wrap(visible, resolvedTheme, custom);
      }
    }

    // Also allow registering renderers for built-in type names.
    final builtInName = field.type == FieldType.switchField
        ? 'switch'
        : field.type.name;
    final override = registry?.rendererFor(builtInName);
    if (override != null) {
      final custom = override(
        FieldRenderContext(
          context: context,
          field: field,
          controller: controller,
          theme: resolvedTheme,
        ),
      );
      return _wrap(visible, resolvedTheme, custom);
    }

    Widget child;
    switch (field.type) {
      case FieldType.text:
      case FieldType.email:
      case FieldType.password:
      case FieldType.number:
      case FieldType.phone:
      case FieldType.multiline:
        child = DynamicTextField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.checkbox:
        child = DynamicCheckboxField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.switchField:
        child = DynamicSwitchField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.radio:
        child = DynamicRadioField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.dropdown:
        child = DynamicDropdownField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.chips:
        child = DynamicChipsField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
        child = DynamicDateTimeField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.group:
        return DynamicGroupField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
          fieldBuilder: this,
        );
      case FieldType.repeatable:
        return DynamicRepeatableField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
          fieldBuilder: this,
        );
      case FieldType.image:
      case FieldType.file:
      case FieldType.camera:
        child = DynamicMediaField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.location:
        child = DynamicLocationField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.slider:
        child = DynamicSliderField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.rangeSlider:
        child = DynamicRangeSliderField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.rating:
        child = DynamicRatingField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.signature:
        child = DynamicSignatureField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.color:
        child = DynamicColorField(
          key: ValueKey<String>('field_${field.key}'),
          field: field,
          controller: controller,
          theme: resolvedTheme,
        );
      case FieldType.custom:
      case FieldType.unknown:
        child = _UnsupportedField(field: field);
    }

    return _wrap(visible, resolvedTheme, child);
  }

  Widget _wrap(bool visible, DynamicFormTheme theme, Widget child) {
    if (!theme.animateFields) {
      return visible ? child : const SizedBox.shrink();
    }
    return AnimatedFormField(
      visible: visible,
      duration: theme.animationDuration,
      curve: theme.animationCurve,
      child: child,
    );
  }
}

class _UnsupportedField extends StatelessWidget {
  const _UnsupportedField({required this.field});

  final FormFieldSchema field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Unsupported field type for "${field.key}" '
        '(${field.customType ?? field.type.name}). '
        'Register a custom renderer via DynamicFormPluginRegistry.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
