import 'package:flutter/foundation.dart';

/// A selectable option for radio, dropdown, or chips fields.
@immutable
class FieldOption {
  /// Creates a [FieldOption].
  const FieldOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// Stored value.
  final dynamic value;

  /// Display label.
  final String label;

  /// Whether the option can be selected.
  final bool enabled;

  /// Parses from a JSON map or shorthand string.
  ///
  /// Accepted shapes:
  /// - `"India"`
  /// - `{"value": "IN", "label": "India"}`
  /// - `{"label": "India"}` (value defaults to label)
  factory FieldOption.fromJson(dynamic json) {
    if (json is String || json is num || json is bool) {
      return FieldOption(value: json, label: json.toString());
    }
    if (json is! Map) {
      throw ArgumentError.value(json, 'json', 'FieldOption expects String or Map');
    }
    final map = Map<String, dynamic>.from(json);
    final label = map['label'] as String? ??
        map['text'] as String? ??
        map['title'] as String? ??
        map['value']?.toString();
    if (label == null || label.isEmpty) {
      throw ArgumentError('FieldOption must include a label or value');
    }
    final value = map.containsKey('value') ? map['value'] : label;
    final enabled = map['enabled'];
    return FieldOption(
      value: value,
      label: label,
      enabled: enabled is bool ? enabled : true,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'value': value,
        'label': label,
        if (!enabled) 'enabled': enabled,
      };

  @override
  String toString() => 'FieldOption(value: $value, label: $label)';
}
