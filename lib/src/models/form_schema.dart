import 'package:flutter/foundation.dart';

import 'form_field_schema.dart';

/// Immutable top-level form schema parsed from JSON.
@immutable
class FormSchema {
  /// Creates a [FormSchema].
  const FormSchema({
    this.title,
    this.description,
    this.submitLabel = 'Submit',
    this.resetLabel = 'Reset',
    this.fields = const <FormFieldSchema>[],
    this.extra = const <String, dynamic>{},
  });

  /// Optional form title.
  final String? title;

  /// Optional form description / subtitle.
  final String? description;

  /// Label for the primary submit action.
  final String submitLabel;

  /// Label for the reset action.
  final String resetLabel;

  /// Ordered list of fields (may include nested groups).
  final List<FormFieldSchema> fields;

  /// Additional free-form metadata.
  final Map<String, dynamic> extra;

  /// All leaf fields flattened across nested groups.
  List<FormFieldSchema> get leafFields =>
      fields.expand((f) => f.leafFields).toList();

  /// Looks up a field by [key] (searches nested groups), or `null`.
  FormFieldSchema? fieldByKey(String key) {
    for (final field in fields) {
      for (final node in field.flattened) {
        if (node.key == key) return node;
      }
    }
    return null;
  }

  /// Builds a [FormSchema] from a JSON map.
  factory FormSchema.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'] ?? json['items'] ?? const <dynamic>[];
    if (rawFields is! List) {
      throw ArgumentError('Form schema "fields" must be a List');
    }

    final fields = <FormFieldSchema>[];
    final seenKeys = <String>{};

    void registerKeys(FormFieldSchema field) {
      if (!seenKeys.add(field.key)) {
        throw ArgumentError('Duplicate field key: "${field.key}"');
      }
      // Repeatable template keys are scoped per item — not globally unique.
      if (field.isRepeatable) return;
      for (final child in field.fields) {
        registerKeys(child);
      }
    }

    for (var i = 0; i < rawFields.length; i++) {
      final item = rawFields[i];
      if (item is! Map) {
        throw ArgumentError('Field at index $i must be a Map');
      }
      final field = FormFieldSchema.fromJson(Map<String, dynamic>.from(item));
      registerKeys(field);
      fields.add(field);
    }

    return FormSchema(
      title: json['title'] as String?,
      description: json['description'] as String?,
      submitLabel: (json['submitLabel'] as String?) ??
          (json['submit_label'] as String?) ??
          'Submit',
      resetLabel: (json['resetLabel'] as String?) ??
          (json['reset_label'] as String?) ??
          'Reset',
      fields: List<FormFieldSchema>.unmodifiable(fields),
      extra: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(json)
          ..removeWhere(
            (k, _) => const {
              'title',
              'description',
              'fields',
              'items',
              'submitLabel',
              'submit_label',
              'resetLabel',
              'reset_label',
            }.contains(k),
          ),
      ),
    );
  }

  /// Serializes this schema to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'submitLabel': submitLabel,
      'resetLabel': resetLabel,
      'fields': fields.map((f) => f.toJson()).toList(),
      ...extra,
    };
  }

  /// Returns a copy with selected fields replaced.
  FormSchema copyWith({
    String? title,
    String? description,
    String? submitLabel,
    String? resetLabel,
    List<FormFieldSchema>? fields,
    Map<String, dynamic>? extra,
  }) {
    return FormSchema(
      title: title ?? this.title,
      description: description ?? this.description,
      submitLabel: submitLabel ?? this.submitLabel,
      resetLabel: resetLabel ?? this.resetLabel,
      fields: fields ?? this.fields,
      extra: extra ?? this.extra,
    );
  }

  @override
  String toString() =>
      'FormSchema(title: $title, fields: ${fields.length})';
}
