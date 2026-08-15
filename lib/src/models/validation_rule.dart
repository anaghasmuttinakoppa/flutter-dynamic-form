import '../core/enums.dart';

/// A single validation rule declared in JSON or constructed in code.
class ValidationRule {
  /// Creates a [ValidationRule].
  const ValidationRule({
    required this.type,
    this.message,
    this.pattern,
    this.min,
    this.max,
    this.value,
    this.field,
    this.operator,
    this.name,
    this.url,
    this.params = const <String, dynamic>{},
  });

  /// Kind of validator to apply.
  final ValidatorType type;

  /// Custom error message override.
  final String? message;

  /// Regex pattern (for [ValidatorType.regex]).
  final String? pattern;

  /// Minimum bound (length / numeric).
  final num? min;

  /// Maximum bound (length / numeric).
  final num? max;

  /// Generic comparison value (literal or unused when [field] is set).
  final dynamic value;

  /// Other field key for [ValidatorType.compare].
  final String? field;

  /// Operator for compare validators (`eq`, `neq`, …).
  final String? operator;

  /// Named async / custom validator key.
  final String? name;

  /// Remote endpoint hint for [ValidatorType.server].
  final String? url;

  /// Extra free-form parameters.
  final Map<String, dynamic> params;

  /// Builds a [ValidationRule] from a JSON map.
  ///
  /// Accepted shapes:
  /// - `{"type": "required", "message": "..."}`
  /// - `{"type": "regex", "pattern": "^\\d+$"}`
  /// - `{"type": "length", "min": 2, "max": 50}`
  /// - `{"type": "compare", "field": "password", "operator": "equals"}`
  /// - `"required"` (shorthand string)
  factory ValidationRule.fromJson(dynamic json) {
    if (json is String) {
      return ValidationRule(type: ValidatorType.fromString(json));
    }

    if (json is! Map) {
      throw ArgumentError.value(
        json,
        'json',
        'ValidationRule expects a String or Map',
      );
    }

    final map = Map<String, dynamic>.from(json);
    final typeName = map['type'] as String? ?? map['name'] as String?;
    final params = Map<String, dynamic>.from(
      (map['params'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );

    return ValidationRule(
      type: ValidatorType.fromString(typeName),
      message: map['message'] as String?,
      pattern: map['pattern'] as String? ?? map['regex'] as String?,
      min: _asNum(map['min'] ?? map['minimum']),
      max: _asNum(map['max'] ?? map['maximum']),
      value: map['value'],
      field: map['field'] as String? ??
          map['otherField'] as String? ??
          map['other_field'] as String? ??
          params['field'] as String?,
      operator: map['operator'] as String? ??
          map['op'] as String? ??
          params['operator'] as String? ??
          params['op'] as String?,
      name: map['name'] as String? ?? params['name'] as String?,
      url: map['url'] as String? ??
          map['endpoint'] as String? ??
          params['url'] as String?,
      params: params,
    );
  }

  /// Serializes this rule to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      if (message != null) 'message': message,
      if (pattern != null) 'pattern': pattern,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (value != null) 'value': value,
      if (field != null) 'field': field,
      if (operator != null) 'operator': operator,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (params.isNotEmpty) 'params': params,
    };
  }

  static num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  @override
  String toString() =>
      'ValidationRule(type: $type, message: $message, min: $min, max: $max)';
}
