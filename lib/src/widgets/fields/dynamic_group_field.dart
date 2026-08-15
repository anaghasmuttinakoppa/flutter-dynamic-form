import 'package:flutter/material.dart';

import '../../builders/field_builder.dart';
import '../../controllers/dynamic_form_controller.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';
import 'field_chrome.dart';

/// Nested group / section field that renders child fields.
class DynamicGroupField extends StatelessWidget {
  /// Creates a [DynamicGroupField].
  const DynamicGroupField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
    this.fieldBuilder = const FieldBuilder(),
  });

  /// Group schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  /// Child field builder.
  final FieldBuilder fieldBuilder;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final material = Theme.of(context);
    final visible = controller.isFieldVisible(field);
    if (!visible) return const SizedBox.shrink();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (field.label != null) ...[
          Text(
            field.label!,
            style: resolved.groupTitleStyle ??
                material.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (field.helperText != null || field.hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                field.helperText ?? field.hint!,
                style: resolved.descriptionStyle ??
                    material.textTheme.bodySmall?.copyWith(
                      color: material.colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          SizedBox(height: resolved.fieldSpacing * 0.75),
        ],
        for (var i = 0; i < field.fields.length; i++) ...[
          fieldBuilder.build(
            context: context,
            field: field.fields[i],
            controller: controller,
            theme: resolved,
          ),
          if (i < field.fields.length - 1)
            SizedBox(height: resolved.fieldSpacing),
        ],
      ],
    );

    if (!resolved.groupDecoration) {
      return AnimatedFormField(visible: visible, child: content);
    }

    return AnimatedFormField(
      visible: visible,
      child: Container(
        padding: resolved.groupPadding,
        decoration: BoxDecoration(
          color: resolved.groupBackgroundColor ??
              material.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(resolved.borderRadius),
          border: Border.all(
            color: resolved.groupBorderColor ?? material.dividerColor,
          ),
        ),
        child: content,
      ),
    );
  }
}
