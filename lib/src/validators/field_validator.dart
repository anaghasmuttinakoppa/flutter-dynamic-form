import '../models/form_field_schema.dart';
import '../models/validation_rule.dart';

/// Context passed to field validators.
class ValidationContext {
  /// Creates a [ValidationContext].
  const ValidationContext({
    required this.field,
    required this.values,
    this.rule,
  });

  /// The field being validated.
  final FormFieldSchema field;

  /// All current form values.
  final Map<String, dynamic> values;

  /// The specific rule being evaluated, if any.
  final ValidationRule? rule;
}

/// Signature for a synchronous field validator.
///
/// Returns an error message when invalid, or `null` when valid.
typedef FieldValidator = String? Function(
  dynamic value,
  ValidationContext context,
);

/// Signature for an asynchronous field validator (Phase 4+).
typedef AsyncFieldValidator = Future<String?> Function(
  dynamic value,
  ValidationContext context,
);
