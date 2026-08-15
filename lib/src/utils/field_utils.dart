import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/enums.dart';
import '../models/form_field_schema.dart';

/// Shared helpers for field rendering.
class FieldUtils {
  FieldUtils._();

  /// Maps a schema [keyboardType] string / field type to a [TextInputType].
  static TextInputType resolveKeyboardType(FormFieldSchema field) {
    final explicit = field.keyboardType?.toLowerCase().trim();
    if (explicit != null) {
      switch (explicit) {
        case 'email':
        case 'emailaddress':
        case 'email_address':
          return TextInputType.emailAddress;
        case 'number':
        case 'numeric':
          return TextInputType.number;
        case 'phone':
        case 'tel':
        case 'telephone':
          return TextInputType.phone;
        case 'url':
          return TextInputType.url;
        case 'multiline':
        case 'textmultiline':
          return TextInputType.multiline;
        case 'name':
          return TextInputType.name;
        case 'visiblepassword':
        case 'visible_password':
          return TextInputType.visiblePassword;
        case 'text':
        default:
          return TextInputType.text;
      }
    }

    switch (field.type) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.number:
        return const TextInputType.numberWithOptions(decimal: true);
      case FieldType.phone:
        return TextInputType.phone;
      case FieldType.multiline:
        return TextInputType.multiline;
      case FieldType.password:
      case FieldType.text:
      case FieldType.checkbox:
      case FieldType.switchField:
      case FieldType.radio:
      case FieldType.dropdown:
      case FieldType.chips:
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
      case FieldType.group:
      case FieldType.repeatable:
      case FieldType.image:
      case FieldType.file:
      case FieldType.camera:
      case FieldType.location:
      case FieldType.slider:
      case FieldType.rangeSlider:
      case FieldType.rating:
      case FieldType.signature:
      case FieldType.color:
      case FieldType.custom:
      case FieldType.unknown:
        return TextInputType.text;
    }
  }

  /// Returns input formatters appropriate for the field type.
  static List<TextInputFormatter> resolveFormatters(FormFieldSchema field) {
    switch (field.type) {
      case FieldType.number:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
        ];
      case FieldType.phone:
        return <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s().\-]')),
        ];
      case FieldType.text:
      case FieldType.email:
      case FieldType.password:
      case FieldType.multiline:
      case FieldType.checkbox:
      case FieldType.switchField:
      case FieldType.radio:
      case FieldType.dropdown:
      case FieldType.chips:
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
      case FieldType.group:
      case FieldType.repeatable:
      case FieldType.image:
      case FieldType.file:
      case FieldType.camera:
      case FieldType.location:
      case FieldType.slider:
      case FieldType.rangeSlider:
      case FieldType.rating:
      case FieldType.signature:
      case FieldType.color:
      case FieldType.custom:
      case FieldType.unknown:
        return const <TextInputFormatter>[];
    }
  }

  /// Resolves a Material icon from a common name string.
  static IconData? resolveIcon(String? name) {
    if (name == null || name.isEmpty) return null;
    switch (name.toLowerCase().trim()) {
      case 'person':
      case 'user':
        return Icons.person_outline;
      case 'email':
      case 'mail':
        return Icons.email_outlined;
      case 'lock':
      case 'password':
        return Icons.lock_outline;
      case 'phone':
      case 'call':
        return Icons.phone_outlined;
      case 'numbers':
      case 'tag':
        return Icons.tag;
      case 'notes':
      case 'description':
        return Icons.notes_outlined;
      case 'visibility':
        return Icons.visibility_outlined;
      case 'visibility_off':
        return Icons.visibility_off_outlined;
      default:
        return null;
    }
  }

  /// Converts a dynamic value to a display string for text controllers.
  static String valueToText(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Parses text back to a typed value for number fields.
  static dynamic parseValue(FormFieldSchema field, String text) {
    if (text.isEmpty) return null;
    if (field.type == FieldType.number) {
      return num.tryParse(text) ?? text;
    }
    return text;
  }
}
