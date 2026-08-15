import 'package:flutter/foundation.dart';

/// Severity of a schema validation issue.
enum SchemaIssueSeverity {
  /// Blocks form rendering.
  error,

  /// Non-blocking notice (e.g. unknown field type).
  warning,
}

/// A single schema validation finding with a JSON path.
@immutable
class SchemaValidationIssue {
  /// Creates a [SchemaValidationIssue].
  const SchemaValidationIssue({
    required this.path,
    required this.message,
    this.severity = SchemaIssueSeverity.error,
    this.fieldKey,
    this.expected,
    this.actual,
  });

  /// JSON-pointer-like path, e.g. `fields[0].key` or `$` for root.
  final String path;

  /// Human-readable description.
  final String message;

  /// Error vs warning.
  final SchemaIssueSeverity severity;

  /// Related field key when known.
  final String? fieldKey;

  /// What was expected (optional).
  final String? expected;

  /// What was found (optional).
  final String? actual;

  @override
  String toString() {
    final buffer = StringBuffer('[$path] $message');
    if (expected != null) buffer.write(' (expected: $expected)');
    if (actual != null) buffer.write(' (got: $actual)');
    return buffer.toString();
  }
}

/// Result of validating a form schema JSON document.
@immutable
class SchemaValidationResult {
  /// Creates a [SchemaValidationResult].
  const SchemaValidationResult({
    this.issues = const <SchemaValidationIssue>[],
  });

  /// All collected issues.
  final List<SchemaValidationIssue> issues;

  /// Whether validation found no errors (warnings allowed).
  bool get isValid =>
      issues.every((i) => i.severity != SchemaIssueSeverity.error);

  /// Error-only issues.
  List<SchemaValidationIssue> get errors => issues
      .where((i) => i.severity == SchemaIssueSeverity.error)
      .toList(growable: false);

  /// Warning-only issues.
  List<SchemaValidationIssue> get warnings => issues
      .where((i) => i.severity == SchemaIssueSeverity.warning)
      .toList(growable: false);

  /// Empty successful result.
  static const SchemaValidationResult success = SchemaValidationResult();

  @override
  String toString() {
    if (isValid && warnings.isEmpty) return 'SchemaValidationResult(ok)';
    return 'SchemaValidationResult(${errors.length} errors, '
        '${warnings.length} warnings)';
  }
}
