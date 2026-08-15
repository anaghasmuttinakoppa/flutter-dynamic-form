import 'dart:convert';

import '../core/exceptions.dart';
import '../models/form_schema.dart';

/// Parses form schemas from JSON maps or JSON strings.
class FormSchemaParser {
  /// Creates a [FormSchemaParser].
  const FormSchemaParser();

  /// Parses a [Map] into a [FormSchema].
  FormSchema parseMap(Map<String, dynamic> json) {
    try {
      return FormSchema.fromJson(json);
    } on ArgumentError catch (e) {
      final message = e.message?.toString() ?? e.toString();
      throw FormSchemaParseException(message, cause: e);
    } catch (e) {
      throw FormSchemaParseException(
        'Failed to parse form schema: $e',
        cause: e,
      );
    }
  }

  /// Parses a JSON [String] into a [FormSchema].
  FormSchema parseString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const FormSchemaParseException(
          'Root JSON value must be an object',
        );
      }
      return parseMap(Map<String, dynamic>.from(decoded));
    } on FormSchemaParseException {
      rethrow;
    } on FormatException catch (e) {
      throw FormSchemaParseException(
        'Invalid JSON: ${e.message}',
        cause: e,
      );
    } catch (e) {
      throw FormSchemaParseException(
        'Failed to parse form schema string: $e',
        cause: e,
      );
    }
  }

  /// Convenience: accepts either a [Map] or a JSON [String].
  FormSchema parse(Object source) {
    if (source is FormSchema) return source;
    if (source is Map<String, dynamic>) return parseMap(source);
    if (source is Map) {
      return parseMap(Map<String, dynamic>.from(source));
    }
    if (source is String) return parseString(source);
    throw FormSchemaParseException(
      'Unsupported schema source type: ${source.runtimeType}',
    );
  }
}
