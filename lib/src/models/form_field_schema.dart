import 'package:flutter/foundation.dart';

import '../core/enums.dart';
import 'field_condition.dart';
import 'field_option.dart';
import 'validation_rule.dart';

/// Immutable schema describing a single form field.
@immutable
class FormFieldSchema {
  /// Creates a [FormFieldSchema].
  const FormFieldSchema({
    required this.key,
    required this.type,
    this.label,
    this.hint,
    this.helperText,
    this.placeholder,
    this.defaultValue,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.visible = true,
    this.obscureText = false,
    this.minLines,
    this.maxLines,
    this.min,
    this.max,
    this.regex,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.options = const <FieldOption>[],
    this.fields = const <FormFieldSchema>[],
    this.visibleWhen,
    this.enabledWhen,
    this.dateFormat,
    this.semanticLabel,
    this.customType,
    this.divisions,
    this.minItems,
    this.maxItems,
    this.allowMultiple = false,
    this.allowedExtensions = const <String>[],
    this.validators = const <ValidationRule>[],
    this.extra = const <String, dynamic>{},
  });

  /// Unique field identifier used as the value map key.
  final String key;

  /// Field widget type.
  final FieldType type;

  /// Visible label above / beside the field.
  final String? label;

  /// Short hint shown below the label or as decoration hint.
  final String? hint;

  /// Helper / description text under the input.
  final String? helperText;

  /// Placeholder text inside an empty input.
  final String? placeholder;

  /// Initial value.
  final dynamic defaultValue;

  /// Whether the field must have a non-empty value.
  final bool required;

  /// Whether the field is interactive (schema default; may be overridden by
  /// [enabledWhen]).
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the field is visible by default (may be overridden by
  /// [visibleWhen]).
  final bool visible;

  /// Whether text should be obscured (passwords).
  final bool obscureText;

  /// Minimum lines for multiline fields.
  final int? minLines;

  /// Maximum lines for text fields.
  final int? maxLines;

  /// Numeric / length minimum constraint.
  final num? min;

  /// Numeric / length maximum constraint.
  final num? max;

  /// Shorthand regex pattern applied as a validator.
  final String? regex;

  /// Keyboard type hint (`text`, `email`, `number`, `phone`, etc.).
  final String? keyboardType;

  /// Material icon name for prefix (resolved by renderer).
  final String? prefixIcon;

  /// Material icon name for suffix.
  final String? suffixIcon;

  /// Options for radio / dropdown / chips.
  final List<FieldOption> options;

  /// Nested child fields for [FieldType.group].
  final List<FormFieldSchema> fields;

  /// Conditional visibility rules (Phase 2).
  final FieldConditionGroup? visibleWhen;

  /// Conditional enabled rules (Phase 2).
  final FieldConditionGroup? enabledWhen;

  /// Optional date/time display format hint (e.g. `yyyy-MM-dd`).
  final String? dateFormat;

  /// Accessibility label override (Phase 5).
  final String? semanticLabel;

  /// Custom type name for [FieldType.custom] / plugin renderers.
  final String? customType;

  /// Slider divisions.
  final int? divisions;

  /// Minimum items for [FieldType.repeatable].
  final int? minItems;

  /// Maximum items for [FieldType.repeatable].
  final int? maxItems;

  /// Whether media pickers allow multiple files.
  final bool allowMultiple;

  /// Allowed file extensions for file pickers.
  final List<String> allowedExtensions;

  /// Explicit validation rules.
  final List<ValidationRule> validators;

  /// Additional free-form metadata for future phases / custom renderers.
  final Map<String, dynamic> extra;

  /// Effective display label (falls back to [key]).
  String get effectiveLabel => label ?? key;

  /// Effective placeholder (falls back to [hint]).
  String? get effectivePlaceholder => placeholder ?? hint;

  /// Whether this field is a nested group container.
  bool get isGroup => type == FieldType.group;

  /// Whether this field is a repeatable list container.
  bool get isRepeatable => type == FieldType.repeatable;

  /// Depth-first list of this field and nested group descendants.
  List<FormFieldSchema> get flattened {
    if (!isGroup) return <FormFieldSchema>[this];
    final result = <FormFieldSchema>[this];
    for (final child in fields) {
      result.addAll(child.flattened);
    }
    return result;
  }

  /// Leaf fields only (excludes group containers; includes repeatable keys).
  List<FormFieldSchema> get leafFields {
    if (!isGroup) return <FormFieldSchema>[this];
    return fields.expand((f) => f.leafFields).toList();
  }

  /// Effective semantics label for accessibility.
  String get effectiveSemanticLabel => semanticLabel ?? effectiveLabel;

  /// Builds a [FormFieldSchema] from a JSON map.
  factory FormFieldSchema.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? json['name'] as String?;
    if (key == null || key.isEmpty) {
      throw ArgumentError('Form field JSON must include a non-empty "key"');
    }

    final rawType = json['type'] as String?;
    final type = FieldType.fromString(rawType);
    final validatorsJson = json['validators'];
    final validators = <ValidationRule>[];

    if (validatorsJson is List) {
      for (final item in validatorsJson) {
        validators.add(ValidationRule.fromJson(item));
      }
    }

    final required = _asBool(json['required']) ?? false;
    if (required &&
        !validators.any((rule) => rule.type == ValidatorType.required)) {
      validators.insert(0, const ValidationRule(type: ValidatorType.required));
    }

    final regex = json['regex'] as String? ?? json['pattern'] as String?;
    if (regex != null &&
        regex.isNotEmpty &&
        !validators.any((rule) => rule.type == ValidatorType.regex)) {
      validators.add(
        ValidationRule(type: ValidatorType.regex, pattern: regex),
      );
    }

    final min = _asNum(json['min'] ?? json['minimum']);
    final max = _asNum(json['max'] ?? json['maximum']);

    if (min != null &&
        type == FieldType.number &&
        !validators.any((rule) => rule.type == ValidatorType.min)) {
      validators.add(ValidationRule(type: ValidatorType.min, min: min));
    }
    if (max != null &&
        type == FieldType.number &&
        !validators.any((rule) => rule.type == ValidatorType.max)) {
      validators.add(ValidationRule(type: ValidatorType.max, max: max));
    }

    if (type == FieldType.email &&
        !validators.any((rule) => rule.type == ValidatorType.email)) {
      validators.add(const ValidationRule(type: ValidatorType.email));
    }
    if (type == FieldType.phone &&
        !validators.any((rule) => rule.type == ValidatorType.phone)) {
      validators.add(const ValidationRule(type: ValidatorType.phone));
    }

    final obscureText = _asBool(json['obscureText']) ??
        _asBool(json['obscure_text']) ??
        type == FieldType.password;

    final optionsJson =
        (type == FieldType.group || type == FieldType.repeatable)
            ? (json['options'] ?? json['choices'])
            : (json['options'] ?? json['items'] ?? json['choices']);
    final options = <FieldOption>[];
    if (optionsJson is List) {
      for (final item in optionsJson) {
        options.add(FieldOption.fromJson(item));
      }
    }

    final childrenJson =
        (type == FieldType.group || type == FieldType.repeatable)
            ? (json['fields'] ?? json['children'] ?? json['items'])
            : (json['fields'] ?? json['children']);
    final children = <FormFieldSchema>[];
    if (childrenJson is List) {
      for (final item in childrenJson) {
        if (item is Map) {
          children.add(
            FormFieldSchema.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    FieldConditionGroup? visibleWhen;
    final visibleRaw = json['visibleWhen'] ??
        json['visible_when'] ??
        json['showWhen'] ??
        json['show_when'] ??
        json['condition'];
    if (visibleRaw != null) {
      visibleWhen = FieldConditionGroup.fromJson(visibleRaw);
    }

    FieldConditionGroup? enabledWhen;
    final enabledRaw = json['enabledWhen'] ??
        json['enabled_when'] ??
        json['enableWhen'] ??
        json['enable_when'];
    if (enabledRaw != null) {
      enabledWhen = FieldConditionGroup.fromJson(enabledRaw);
    }

    dynamic defaultValue =
        json['defaultValue'] ?? json['default'] ?? json['value'];
    if (defaultValue == null) {
      if (type == FieldType.checkbox || type == FieldType.switchField) {
        defaultValue = false;
      } else if (type == FieldType.chips ||
          type == FieldType.repeatable ||
          type == FieldType.signature) {
        defaultValue = <dynamic>[];
      } else if (type == FieldType.slider) {
        defaultValue = min ?? 0;
      } else if (type == FieldType.rangeSlider) {
        defaultValue = <num>[min ?? 0, max ?? 1];
      } else if (type == FieldType.rating) {
        defaultValue = 0;
      } else if (type == FieldType.color) {
        defaultValue = '#2196F3';
      }
    }

    final allowedExt = json['allowedExtensions'] ??
        json['allowed_extensions'] ??
        json['accept'];
    final extensions = <String>[];
    if (allowedExt is List) {
      extensions.addAll(allowedExt.map((e) => e.toString()));
    } else if (allowedExt is String && allowedExt.isNotEmpty) {
      extensions.addAll(
        allowedExt.split(RegExp(r'[,;\s]+')).where((e) => e.isNotEmpty),
      );
    }

    return FormFieldSchema(
      key: key,
      type: type,
      label: json['label'] as String?,
      hint: json['hint'] as String?,
      helperText:
          json['helperText'] as String? ?? json['helper_text'] as String?,
      placeholder: json['placeholder'] as String?,
      defaultValue: defaultValue,
      required: required,
      enabled: _asBool(json['enabled']) ?? true,
      readOnly:
          _asBool(json['readOnly']) ?? _asBool(json['read_only']) ?? false,
      visible: _asBool(json['visible']) ?? true,
      obscureText: obscureText,
      minLines: _asInt(json['minLines'] ?? json['min_lines']),
      maxLines: _asInt(json['maxLines'] ?? json['max_lines']),
      min: min,
      max: max,
      regex: regex,
      keyboardType:
          json['keyboardType'] as String? ?? json['keyboard_type'] as String?,
      prefixIcon:
          json['prefixIcon'] as String? ?? json['prefix_icon'] as String?,
      suffixIcon:
          json['suffixIcon'] as String? ?? json['suffix_icon'] as String?,
      options: List<FieldOption>.unmodifiable(options),
      fields: List<FormFieldSchema>.unmodifiable(children),
      visibleWhen: visibleWhen,
      enabledWhen: enabledWhen,
      dateFormat:
          json['dateFormat'] as String? ?? json['date_format'] as String?,
      semanticLabel: json['semanticLabel'] as String? ??
          json['semantic_label'] as String?,
      customType: json['customType'] as String? ??
          json['custom_type'] as String? ??
          (type == FieldType.custom ? rawType : null) ??
          (type == FieldType.unknown ? rawType : null) ??
          json['renderer'] as String?,
      divisions: _asInt(json['divisions']),
      minItems: _asInt(json['minItems'] ?? json['min_items']),
      maxItems: _asInt(json['maxItems'] ?? json['max_items']),
      allowMultiple: _asBool(json['allowMultiple']) ??
          _asBool(json['allow_multiple']) ??
          false,
      allowedExtensions: List<String>.unmodifiable(extensions),
      validators: List<ValidationRule>.unmodifiable(validators),
      extra: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(json)
          ..removeWhere(
            (k, _) => _knownKeys.contains(k),
          ),
      ),
    );
  }

  static const Set<String> _knownKeys = {
    'key',
    'name',
    'type',
    'label',
    'hint',
    'helperText',
    'helper_text',
    'placeholder',
    'defaultValue',
    'default',
    'value',
    'required',
    'enabled',
    'readOnly',
    'read_only',
    'visible',
    'obscureText',
    'obscure_text',
    'minLines',
    'min_lines',
    'maxLines',
    'max_lines',
    'min',
    'minimum',
    'max',
    'maximum',
    'regex',
    'pattern',
    'keyboardType',
    'keyboard_type',
    'prefixIcon',
    'prefix_icon',
    'suffixIcon',
    'suffix_icon',
    'validators',
    'options',
    'items',
    'choices',
    'fields',
    'children',
    'visibleWhen',
    'visible_when',
    'showWhen',
    'show_when',
    'condition',
    'enabledWhen',
    'enabled_when',
    'enableWhen',
    'enable_when',
    'dateFormat',
    'date_format',
    'semanticLabel',
    'semantic_label',
    'customType',
    'custom_type',
    'renderer',
    'divisions',
    'minItems',
    'min_items',
    'maxItems',
    'max_items',
    'allowMultiple',
    'allow_multiple',
    'allowedExtensions',
    'allowed_extensions',
    'accept',
  };

  /// Serializes this schema to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'type': type == FieldType.switchField ? 'switch' : type.name,
      if (label != null) 'label': label,
      if (hint != null) 'hint': hint,
      if (helperText != null) 'helperText': helperText,
      if (placeholder != null) 'placeholder': placeholder,
      if (defaultValue != null) 'defaultValue': defaultValue,
      'required': required,
      'enabled': enabled,
      'readOnly': readOnly,
      'visible': visible,
      'obscureText': obscureText,
      if (minLines != null) 'minLines': minLines,
      if (maxLines != null) 'maxLines': maxLines,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (regex != null) 'regex': regex,
      if (keyboardType != null) 'keyboardType': keyboardType,
      if (prefixIcon != null) 'prefixIcon': prefixIcon,
      if (suffixIcon != null) 'suffixIcon': suffixIcon,
      if (options.isNotEmpty)
        'options': options.map((o) => o.toJson()).toList(),
      if (fields.isNotEmpty) 'fields': fields.map((f) => f.toJson()).toList(),
      if (visibleWhen != null && !visibleWhen!.isEmpty)
        'visibleWhen': visibleWhen!.toJson(),
      if (enabledWhen != null && !enabledWhen!.isEmpty)
        'enabledWhen': enabledWhen!.toJson(),
      if (dateFormat != null) 'dateFormat': dateFormat,
      if (semanticLabel != null) 'semanticLabel': semanticLabel,
      if (customType != null) 'customType': customType,
      if (divisions != null) 'divisions': divisions,
      if (minItems != null) 'minItems': minItems,
      if (maxItems != null) 'maxItems': maxItems,
      if (allowMultiple) 'allowMultiple': allowMultiple,
      if (allowedExtensions.isNotEmpty)
        'allowedExtensions': allowedExtensions,
      if (validators.isNotEmpty)
        'validators': validators.map((v) => v.toJson()).toList(),
      ...extra,
    };
  }

  /// Returns a copy with selected fields replaced.
  FormFieldSchema copyWith({
    String? key,
    FieldType? type,
    String? label,
    String? hint,
    String? helperText,
    String? placeholder,
    dynamic defaultValue,
    bool? required,
    bool? enabled,
    bool? readOnly,
    bool? visible,
    bool? obscureText,
    int? minLines,
    int? maxLines,
    num? min,
    num? max,
    String? regex,
    String? keyboardType,
    String? prefixIcon,
    String? suffixIcon,
    List<FieldOption>? options,
    List<FormFieldSchema>? fields,
    FieldConditionGroup? visibleWhen,
    FieldConditionGroup? enabledWhen,
    String? dateFormat,
    String? semanticLabel,
    String? customType,
    int? divisions,
    int? minItems,
    int? maxItems,
    bool? allowMultiple,
    List<String>? allowedExtensions,
    List<ValidationRule>? validators,
    Map<String, dynamic>? extra,
  }) {
    return FormFieldSchema(
      key: key ?? this.key,
      type: type ?? this.type,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      helperText: helperText ?? this.helperText,
      placeholder: placeholder ?? this.placeholder,
      defaultValue: defaultValue ?? this.defaultValue,
      required: required ?? this.required,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      visible: visible ?? this.visible,
      obscureText: obscureText ?? this.obscureText,
      minLines: minLines ?? this.minLines,
      maxLines: maxLines ?? this.maxLines,
      min: min ?? this.min,
      max: max ?? this.max,
      regex: regex ?? this.regex,
      keyboardType: keyboardType ?? this.keyboardType,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      options: options ?? this.options,
      fields: fields ?? this.fields,
      visibleWhen: visibleWhen ?? this.visibleWhen,
      enabledWhen: enabledWhen ?? this.enabledWhen,
      dateFormat: dateFormat ?? this.dateFormat,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      customType: customType ?? this.customType,
      divisions: divisions ?? this.divisions,
      minItems: minItems ?? this.minItems,
      maxItems: maxItems ?? this.maxItems,
      allowMultiple: allowMultiple ?? this.allowMultiple,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      validators: validators ?? this.validators,
      extra: extra ?? this.extra,
    );
  }

  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static int? _asInt(dynamic value) {
    final n = _asNum(value);
    return n?.toInt();
  }

  @override
  String toString() =>
      'FormFieldSchema(key: $key, type: $type, required: $required)';
}
