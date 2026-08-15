import 'dart:convert';

import '../core/enums.dart';
import '../models/schema_validation_issue.dart';

/// Validates form schema JSON **before** rendering, collecting all issues
/// with JSON paths so the UI can show where the schema is wrong.
class FormSchemaValidator {
  /// Creates a [FormSchemaValidator].
  const FormSchemaValidator();

  /// Known / supported field type aliases (lowercase).
  static const Set<String> supportedTypeAliases = {
    'text',
    'string',
    'email',
    'password',
    'number',
    'int',
    'integer',
    'double',
    'numeric',
    'phone',
    'tel',
    'telephone',
    'multiline',
    'textarea',
    'text_area',
    'checkbox',
    'check',
    'bool',
    'boolean',
    'switch',
    'toggle',
    'radio',
    'radiogroup',
    'radio_group',
    'dropdown',
    'select',
    'selectbox',
    'chips',
    'chip',
    'multiselect',
    'multi_select',
    'date',
    'datepicker',
    'date_picker',
    'time',
    'timepicker',
    'time_picker',
    'datetime',
    'date_time',
    'datetimepicker',
    'date_time_picker',
    'group',
    'section',
    'nested',
    'fieldset',
    'repeatable',
    'repeater',
    'list',
    'array',
    'image',
    'imagepicker',
    'image_picker',
    'photo',
    'file',
    'filepicker',
    'file_picker',
    'attachment',
    'camera',
    'capture',
    'location',
    'geo',
    'geolocation',
    'gps',
    'slider',
    'rangeslider',
    'range_slider',
    'range',
    'rating',
    'stars',
    'signature',
    'sign',
    'color',
    'colorpicker',
    'color_picker',
    'custom',
  };

  /// Validates a schema source ([Map], JSON [String], or already-parsed map).
  SchemaValidationResult validate(Object source) {
    final issues = <SchemaValidationIssue>[];

    Map<String, dynamic>? root;
    if (source is String) {
      try {
        final decoded = jsonDecode(source);
        if (decoded is! Map) {
          issues.add(
            const SchemaValidationIssue(
              path: r'$',
              message: 'Root JSON value must be an object `{ ... }`',
              expected: 'object',
              actual: 'non-object',
            ),
          );
          return SchemaValidationResult(issues: issues);
        }
        root = Map<String, dynamic>.from(decoded);
      } on FormatException catch (e) {
        issues.add(
          SchemaValidationIssue(
            path: r'$',
            message: 'Invalid JSON syntax: ${e.message}',
            actual: e.source?.toString(),
          ),
        );
        return SchemaValidationResult(issues: issues);
      } catch (e) {
        issues.add(
          SchemaValidationIssue(
            path: r'$',
            message: 'Failed to decode JSON: $e',
          ),
        );
        return SchemaValidationResult(issues: issues);
      }
    } else if (source is Map<String, dynamic>) {
      root = source;
    } else if (source is Map) {
      root = Map<String, dynamic>.from(source);
    } else {
      issues.add(
        SchemaValidationIssue(
          path: r'$',
          message:
              'Unsupported schema source type: ${source.runtimeType}. '
              'Pass a Map or JSON String.',
          expected: 'Map or String',
          actual: source.runtimeType.toString(),
        ),
      );
      return SchemaValidationResult(issues: issues);
    }

    _validateRoot(root, issues);
    return SchemaValidationResult(issues: List.unmodifiable(issues));
  }

  void _validateRoot(Map<String, dynamic> json, List<SchemaValidationIssue> out) {
    for (final key in const ['title', 'description', 'submitLabel', 'resetLabel']) {
      final alt = key == 'submitLabel'
          ? json['submit_label']
          : key == 'resetLabel'
              ? json['reset_label']
              : null;
      final value = json[key] ?? alt;
      if (value != null && value is! String) {
        out.add(
          SchemaValidationIssue(
            path: key,
            message: '"$key" must be a string',
            expected: 'string',
            actual: value.runtimeType.toString(),
          ),
        );
      }
    }

    final rawFields = json['fields'] ?? json['items'];
    if (rawFields == null) {
      out.add(
        const SchemaValidationIssue(
          path: 'fields',
          message: 'Missing required "fields" array',
          expected: 'array of field objects',
          actual: 'null',
        ),
      );
      return;
    }

    if (rawFields is! List) {
      out.add(
        SchemaValidationIssue(
          path: 'fields',
          message: '"fields" must be an array',
          expected: 'array',
          actual: rawFields.runtimeType.toString(),
        ),
      );
      return;
    }

    if (rawFields.isEmpty) {
      out.add(
        const SchemaValidationIssue(
          path: 'fields',
          message: '"fields" must contain at least one field',
          expected: 'non-empty array',
          actual: '[]',
        ),
      );
    }

    final seenKeys = <String>{};
    for (var i = 0; i < rawFields.length; i++) {
      _validateField(
        rawFields[i],
        path: 'fields[$i]',
        seenKeys: seenKeys,
        out: out,
        insideRepeatable: false,
      );
    }
  }

  void _validateField(
    dynamic raw, {
    required String path,
    required Set<String> seenKeys,
    required List<SchemaValidationIssue> out,
    required bool insideRepeatable,
  }) {
    if (raw is! Map) {
      out.add(
        SchemaValidationIssue(
          path: path,
          message: 'Field must be an object `{ ... }`',
          expected: 'object',
          actual: raw.runtimeType.toString(),
        ),
      );
      return;
    }

    final json = Map<String, dynamic>.from(raw);
    final key = json['key'] as String? ?? json['name'] as String?;
    if (key == null || key.trim().isEmpty) {
      out.add(
        SchemaValidationIssue(
          path: '$path.key',
          message: 'Field is missing a non-empty "key"',
          expected: 'non-empty string',
          actual: key == null ? 'null' : '""',
        ),
      );
    } else if (!insideRepeatable) {
      if (!seenKeys.add(key)) {
        out.add(
          SchemaValidationIssue(
            path: '$path.key',
            message: 'Duplicate field key "$key"',
            fieldKey: key,
            expected: 'unique key',
            actual: key,
          ),
        );
      }
    }

    final typeRaw = json['type'];
    if (typeRaw == null) {
      out.add(
        SchemaValidationIssue(
          path: '$path.type',
          message: 'Field is missing "type"',
          fieldKey: key,
          expected: 'string field type',
          actual: 'null',
        ),
      );
    } else if (typeRaw is! String || typeRaw.trim().isEmpty) {
      out.add(
        SchemaValidationIssue(
          path: '$path.type',
          message: '"type" must be a non-empty string',
          fieldKey: key,
          expected: 'string',
          actual: typeRaw.runtimeType.toString(),
        ),
      );
    } else {
      final alias = typeRaw.toLowerCase().trim();
      if (!supportedTypeAliases.contains(alias)) {
        final resolved = FieldType.fromString(alias);
        if (resolved == FieldType.unknown && alias != 'custom') {
          out.add(
            SchemaValidationIssue(
              path: '$path.type',
              message:
                  'Unknown field type "$typeRaw". '
                  'Register a custom renderer or use a supported type.',
              fieldKey: key,
              severity: SchemaIssueSeverity.warning,
              expected: 'supported type or custom',
              actual: typeRaw,
            ),
          );
        }
      }
    }

    final type = FieldType.fromString(typeRaw is String ? typeRaw : null);

    _expectBool(json, 'required', path, out, fieldKey: key);
    _expectBool(json, 'enabled', path, out, fieldKey: key);
    _expectBool(json, 'visible', path, out, fieldKey: key);
    _expectBool(json, 'readOnly', path, out, fieldKey: key);
    _expectBool(json, 'read_only', path, out, fieldKey: key);

    if (json.containsKey('validators') && json['validators'] is! List) {
      out.add(
        SchemaValidationIssue(
          path: '$path.validators',
          message: '"validators" must be an array',
          fieldKey: key,
          expected: 'array',
          actual: json['validators'].runtimeType.toString(),
        ),
      );
    } else if (json['validators'] is List) {
      final validators = json['validators'] as List;
      for (var i = 0; i < validators.length; i++) {
        final v = validators[i];
        if (v is String) continue;
        if (v is! Map) {
          out.add(
            SchemaValidationIssue(
              path: '$path.validators[$i]',
              message: 'Validator must be a string or object',
              fieldKey: key,
              expected: 'string | object',
              actual: v.runtimeType.toString(),
            ),
          );
          continue;
        }
        final typeName = v['type'] ?? v['name'];
        if (typeName != null && typeName is! String) {
          out.add(
            SchemaValidationIssue(
              path: '$path.validators[$i].type',
              message: 'Validator "type" must be a string',
              fieldKey: key,
            ),
          );
        }
      }
    }

    final needsOptions = type == FieldType.radio ||
        type == FieldType.dropdown ||
        type == FieldType.chips;
    if (needsOptions) {
      final options = json['options'] ?? json['items'] ?? json['choices'];
      if (options == null) {
        out.add(
          SchemaValidationIssue(
            path: '$path.options',
            message: '"$type" fields should declare "options"',
            fieldKey: key,
            severity: SchemaIssueSeverity.warning,
            expected: 'array',
            actual: 'null',
          ),
        );
      } else if (options is! List) {
        out.add(
          SchemaValidationIssue(
            path: '$path.options',
            message: '"options" must be an array',
            fieldKey: key,
            expected: 'array',
            actual: options.runtimeType.toString(),
          ),
        );
      }
    }

    final isContainer =
        type == FieldType.group || type == FieldType.repeatable;
    if (isContainer) {
      final children = json['fields'] ?? json['children'] ?? json['items'];
      if (children == null) {
        out.add(
          SchemaValidationIssue(
            path: '$path.fields',
            message: '"${type.name}" requires nested "fields"',
            fieldKey: key,
            expected: 'array of fields',
            actual: 'null',
          ),
        );
      } else if (children is! List) {
        out.add(
          SchemaValidationIssue(
            path: '$path.fields',
            message: 'Nested "fields" must be an array',
            fieldKey: key,
            expected: 'array',
            actual: children.runtimeType.toString(),
          ),
        );
      } else {
        final childKeys = <String>{};
        for (var i = 0; i < children.length; i++) {
          _validateField(
            children[i],
            path: '$path.fields[$i]',
            seenKeys: type == FieldType.group ? seenKeys : childKeys,
            out: out,
            insideRepeatable: type == FieldType.repeatable,
          );
        }
      }
    }
  }

  void _expectBool(
    Map<String, dynamic> json,
    String key,
    String path,
    List<SchemaValidationIssue> out, {
    String? fieldKey,
  }) {
    if (!json.containsKey(key)) return;
    final value = json[key];
    if (value is bool || value is num) return;
    if (value is String) {
      final s = value.toLowerCase();
      if (s == 'true' || s == 'false' || s == '1' || s == '0') return;
    }
    out.add(
      SchemaValidationIssue(
        path: '$path.$key',
        message: '"$key" must be a boolean',
        fieldKey: fieldKey,
        expected: 'boolean',
        actual: value.runtimeType.toString(),
      ),
    );
  }
}
