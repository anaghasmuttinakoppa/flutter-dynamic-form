/// Base exception for the json_dynamic_form package.
class DynamicFormException implements Exception {
  /// Creates a [DynamicFormException] with a human-readable [message].
  const DynamicFormException(this.message, {this.cause});

  /// Human-readable error description.
  final String message;

  /// Optional underlying cause.
  final Object? cause;

  @override
  String toString() => 'DynamicFormException: $message';
}

/// Thrown when JSON schema parsing fails.
class FormSchemaParseException extends DynamicFormException {
  /// Creates a parse exception.
  const FormSchemaParseException(super.message, {super.cause, this.fieldKey});

  /// Field key related to the parse failure, if any.
  final String? fieldKey;

  @override
  String toString() {
    final keyPart = fieldKey != null ? ' (field: $fieldKey)' : '';
    return 'FormSchemaParseException$keyPart: $message';
  }
}

/// Thrown when validation configuration is invalid.
class ValidatorConfigException extends DynamicFormException {
  /// Creates a validator configuration exception.
  const ValidatorConfigException(super.message, {super.cause});
}
