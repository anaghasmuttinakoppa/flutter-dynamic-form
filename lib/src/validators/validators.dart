import '../core/enums.dart';
import '../models/form_field_schema.dart';
import '../models/media_value.dart';
import '../models/validation_rule.dart';
import 'field_validator.dart';

/// Built-in validators and a small engine that evaluates field rules.
class Validators {
  Validators._();

  /// Simple email pattern (intentionally pragmatic, not RFC-complete).
  static final RegExp emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
  );

  /// Loose phone pattern allowing digits, spaces, +, -, (, ).
  static final RegExp phonePattern = RegExp(r'^\+?[\d\s().-]{7,20}$');

  /// Required: rejects null / empty / whitespace-only strings / false bools
  /// for checkboxes when required.
  static FieldValidator required([String? message]) {
    return (value, context) {
      if (_isEmpty(value)) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} is required';
      }
      // Required checkbox/switch must be checked (true).
      if ((context.field.type == FieldType.checkbox ||
              context.field.type == FieldType.switchField) &&
          value != true) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} is required';
      }
      return null;
    };
  }

  /// Email format validator.
  static FieldValidator email([String? message]) {
    return (value, context) {
      if (_isEmpty(value)) return null;
      final text = value.toString().trim();
      if (!emailPattern.hasMatch(text)) {
        return message ??
            context.rule?.message ??
            'Enter a valid email address';
      }
      return null;
    };
  }

  /// Phone format validator.
  static FieldValidator phone([String? message]) {
    return (value, context) {
      if (_isEmpty(value)) return null;
      final text = value.toString().trim();
      if (!phonePattern.hasMatch(text)) {
        return message ??
            context.rule?.message ??
            'Enter a valid phone number';
      }
      return null;
    };
  }

  /// Regex validator.
  static FieldValidator regex(String pattern, [String? message]) {
    final re = RegExp(pattern);
    return (value, context) {
      if (_isEmpty(value)) return null;
      if (!re.hasMatch(value.toString())) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} is invalid';
      }
      return null;
    };
  }

  /// String length validator.
  static FieldValidator length({int? min, int? max, String? message}) {
    return (value, context) {
      if (_isEmpty(value)) return null;
      final len = value is Iterable ? value.length : value.toString().length;
      if (min != null && len < min) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} must be at least $min characters';
      }
      if (max != null && len > max) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} must be at most $max characters';
      }
      return null;
    };
  }

  /// Numeric minimum validator.
  static FieldValidator min(num minimum, [String? message]) {
    return (value, context) {
      if (_isEmpty(value)) return null;
      final number = _asNum(value);
      if (number == null) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} must be a number';
      }
      if (number < minimum) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} must be at least $minimum';
      }
      return null;
    };
  }

  /// Numeric maximum validator.
  static FieldValidator max(num maximum, [String? message]) {
    return (value, context) {
      if (_isEmpty(value)) return null;
      final number = _asNum(value);
      if (number == null) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} must be a number';
      }
      if (number > maximum) {
        return message ??
            context.rule?.message ??
            '${context.field.effectiveLabel} must be at most $maximum';
      }
      return null;
    };
  }

  /// Compares this field's value to another field or a literal.
  static FieldValidator compare({
    String? otherField,
    dynamic literal,
    ConditionOperator operator = ConditionOperator.equals,
    String? message,
  }) {
    return (value, context) {
      if (_isEmpty(value) && literal == null && otherField == null) {
        return null;
      }
      final other = otherField != null
          ? context.values[otherField]
          : literal;

      final passes = switch (operator) {
        ConditionOperator.equals => _equals(value, other),
        ConditionOperator.notEquals => !_equals(value, other),
        ConditionOperator.greaterThan => _compare(value, other) > 0,
        ConditionOperator.greaterThanOrEqual => _compare(value, other) >= 0,
        ConditionOperator.lessThan => _compare(value, other) < 0,
        ConditionOperator.lessThanOrEqual => _compare(value, other) <= 0,
        ConditionOperator.contains =>
          value?.toString().contains(other?.toString() ?? '') ?? false,
        ConditionOperator.isEmpty => _isEmpty(value),
        ConditionOperator.isNotEmpty => !_isEmpty(value),
        ConditionOperator.isIn =>
          other is Iterable && other.any((e) => _equals(value, e)),
      };

      if (passes) return null;
      return message ??
          context.rule?.message ??
          (otherField != null
              ? '${context.field.effectiveLabel} must match $otherField'
              : '${context.field.effectiveLabel} is invalid');
    };
  }

  /// Resolves a [ValidationRule] into a concrete [FieldValidator].
  static FieldValidator fromRule(ValidationRule rule) {
    switch (rule.type) {
      case ValidatorType.required:
        return required(rule.message);
      case ValidatorType.email:
        return email(rule.message);
      case ValidatorType.phone:
        return phone(rule.message);
      case ValidatorType.regex:
        final pattern = rule.pattern;
        if (pattern == null || pattern.isEmpty) {
          return (_, __) => null;
        }
        return regex(pattern, rule.message);
      case ValidatorType.length:
        return length(
          min: rule.min?.toInt(),
          max: rule.max?.toInt(),
          message: rule.message,
        );
      case ValidatorType.min:
        final minimum = rule.min ?? _asNum(rule.value);
        if (minimum == null) return (_, __) => null;
        return min(minimum, rule.message);
      case ValidatorType.max:
        final maximum = rule.max ?? _asNum(rule.value);
        if (maximum == null) return (_, __) => null;
        return max(maximum, rule.message);
      case ValidatorType.compare:
        return compare(
          otherField: rule.field,
          literal: rule.field == null ? rule.value : null,
          operator: ConditionOperator.fromString(rule.operator),
          message: rule.message,
        );
      case ValidatorType.async:
      case ValidatorType.server:
        // Handled asynchronously by DynamicFormController.
        return (_, __) => null;
      case ValidatorType.custom:
        return (_, __) => null;
    }
  }

  /// Runs all validators for [field] against [value] using [values].
  ///
  /// Returns the first error message, or `null` if valid.
  static String? validateField({
    required FormFieldSchema field,
    required dynamic value,
    required Map<String, dynamic> values,
    Map<String, FieldValidator>? customValidators,
  }) {
    for (final rule in field.validators) {
      final context = ValidationContext(
        field: field,
        values: values,
        rule: rule,
      );

      FieldValidator? validator = fromRule(rule);
      if (rule.type == ValidatorType.custom) {
        final name = rule.params['name'] as String? ??
            rule.pattern ??
            rule.field;
        if (name != null && customValidators != null) {
          validator = customValidators[name] ?? validator;
        }
      }

      final error = validator(value, context);
      if (error != null) return error;
    }
    return null;
  }

  static bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is MediaFileValue) return value.isEmpty;
    if (value is LocationValue) return false;
    return false;
  }

  static bool _equals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a is num && b is num) return a == b;
    return a.toString() == b.toString();
  }

  static int _compare(dynamic a, dynamic b) {
    final an = _asNum(a);
    final bn = _asNum(b);
    if (an != null && bn != null) return an.compareTo(bn);
    return a.toString().compareTo(b.toString());
  }

  static num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().trim());
  }
}
