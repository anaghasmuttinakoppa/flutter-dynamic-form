import 'package:flutter/material.dart';

import '../../builders/field_builder.dart';
import '../../controllers/dynamic_form_controller.dart';
import '../../core/enums.dart';
import '../../l10n/dynamic_form_localizations.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';
import 'field_chrome.dart';

/// Repeatable section of nested fields (Phase 5).
class DynamicRepeatableField extends StatelessWidget {
  /// Creates a [DynamicRepeatableField].
  const DynamicRepeatableField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
    this.fieldBuilder = const FieldBuilder(),
  });

  /// Repeatable schema (template in [FormFieldSchema.fields]).
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  /// Builder for nested template fields (reserved for future expansion).
  final FieldBuilder fieldBuilder;

  @override
  Widget build(BuildContext context) {
    final resolved = theme ?? DynamicFormThemeProvider.of(context);
    final l10n = DynamicFormLocalizations.of(context);
    final visible = controller.isFieldVisible(field);
    if (!visible) return const SizedBox.shrink();

    final enabled = controller.isFieldEnabled(field);
    final error = controller.errorFor(field.key);
    final material = Theme.of(context);
    final raw = controller.getValue(field.key);
    final items = raw is List
        ? raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList()
        : <Map<String, dynamic>>[];

    final canAdd =
        enabled && (field.maxItems == null || items.length < field.maxItems!);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          field.effectiveLabel,
          style: resolved.groupTitleStyle ??
              material.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (field.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(field.helperText!, style: resolved.helperStyle),
          ),
        for (var i = 0; i < items.length; i++) ...[
          _RepeatableItem(
            index: i,
            field: field,
            item: items[i],
            controller: controller,
            theme: resolved,
            enabled: enabled,
            title: l10n.format(l10n.itemLabel, {'index': '${i + 1}'}),
            removeLabel: l10n.removeItemLabel,
            canRemove: enabled &&
                (field.minItems == null || items.length > field.minItems!),
          ),
          SizedBox(height: resolved.fieldSpacing),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: canAdd
                ? () => controller.addRepeatableItem(field.key)
                : null,
            icon: const Icon(Icons.add),
            label: Text(l10n.addItemLabel),
          ),
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
    );

    return AnimatedFormField(
      visible: visible,
      duration: resolved.animationDuration,
      curve: resolved.animationCurve,
      child: Semantics(
        label: field.effectiveSemanticLabel,
        child: resolved.groupDecoration
            ? Container(
                padding: resolved.groupPadding,
                decoration: BoxDecoration(
                  color: resolved.groupBackgroundColor ??
                      material.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(resolved.borderRadius),
                  border: Border.all(
                    color:
                        resolved.groupBorderColor ?? material.dividerColor,
                  ),
                ),
                child: body,
              )
            : body,
      ),
    );
  }
}

class _RepeatableItem extends StatelessWidget {
  const _RepeatableItem({
    required this.index,
    required this.field,
    required this.item,
    required this.controller,
    required this.theme,
    required this.enabled,
    required this.title,
    required this.removeLabel,
    required this.canRemove,
  });

  final int index;
  final FormFieldSchema field;
  final Map<String, dynamic> item;
  final DynamicFormController controller;
  final DynamicFormTheme theme;
  final bool enabled;
  final String title;
  final String removeLabel;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: removeLabel,
                onPressed: () =>
                    controller.removeRepeatableItem(field.key, index),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        for (var i = 0; i < field.fields.length; i++) ...[
          _InlineField(
            schema: field.fields[i],
            value: item[field.fields[i].key],
            enabled: enabled && field.fields[i].enabled,
            theme: theme,
            onChanged: (v) => controller.updateRepeatableItemField(
              field.key,
              index,
              field.fields[i].key,
              v,
            ),
          ),
          if (i < field.fields.length - 1)
            SizedBox(height: theme.fieldSpacing * 0.75),
        ],
      ],
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.schema,
    required this.value,
    required this.enabled,
    required this.theme,
    required this.onChanged,
  });

  final FormFieldSchema schema;
  final dynamic value;
  final bool enabled;
  final DynamicFormTheme theme;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    if (schema.type == FieldType.checkbox ||
        schema.type == FieldType.switchField) {
      return CheckboxListTile(
        value: value == true,
        title: Text(schema.effectiveLabel),
        dense: theme.dense,
        contentPadding: EdgeInsets.zero,
        onChanged: enabled ? (v) => onChanged(v ?? false) : null,
      );
    }

    if (schema.type == FieldType.number) {
      return TextFormField(
        initialValue: value?.toString() ?? '',
        enabled: enabled,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: schema.label,
          hintText: schema.effectivePlaceholder,
          filled: true,
          isDense: theme.dense,
          contentPadding: theme.contentPadding,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius),
          ),
        ),
        onChanged: (text) => onChanged(num.tryParse(text) ?? text),
      );
    }

    return TextFormField(
      initialValue: value?.toString() ?? '',
      enabled: enabled,
      decoration: InputDecoration(
        labelText: schema.label,
        hintText: schema.effectivePlaceholder,
        filled: true,
        isDense: theme.dense,
        contentPadding: theme.contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
      ),
      onChanged: onChanged,
    );
  }
}
