import 'package:flutter/foundation.dart';

import '../core/enums.dart';

/// A single condition that can drive visibility / enabled state.
///
/// JSON examples:
/// ```json
/// { "field": "country", "operator": "equals", "value": "India" }
/// { "field": "age", "op": "lt", "value": 18 }
/// { "field": "tags", "operator": "contains", "value": "vip" }
/// ```
@immutable
class FieldCondition {
  /// Creates a [FieldCondition].
  const FieldCondition({
    required this.field,
    this.operator = ConditionOperator.equals,
    this.value,
  });

  /// Key of the field whose value is evaluated.
  final String field;

  /// Comparison operator.
  final ConditionOperator operator;

  /// Expected value (ignored for empty / notEmpty).
  final dynamic value;

  /// Parses from JSON.
  factory FieldCondition.fromJson(Map<String, dynamic> json) {
    // Shorthand: { "country": "India" } → equals
    if (json.length == 1 &&
        !json.containsKey('field') &&
        !json.containsKey('when') &&
        !json.containsKey('key')) {
      final entry = json.entries.first;
      return FieldCondition(
        field: entry.key,
        value: entry.value,
      );
    }

    final field = json['field'] as String? ??
        json['when'] as String? ??
        json['key'] as String? ??
        json['dependsOn'] as String? ??
        json['depends_on'] as String?;
    if (field == null || field.isEmpty) {
      throw ArgumentError('FieldCondition requires a "field" key');
    }

    final opRaw = json['operator'] as String? ??
        json['op'] as String? ??
        json['comparison'] as String?;

    // Shorthand keys: { "field": "age", "lt": 18 }
    ConditionOperator? inlineOp;
    dynamic inlineValue;
    for (final key in const [
      'eq',
      'equals',
      'neq',
      'gt',
      'gte',
      'lt',
      'lte',
      'contains',
      'in',
      'empty',
      'notEmpty',
    ]) {
      if (json.containsKey(key)) {
        inlineOp = ConditionOperator.fromString(key);
        inlineValue = json[key];
        break;
      }
    }

    return FieldCondition(
      field: field,
      operator: inlineOp ?? ConditionOperator.fromString(opRaw),
      value: inlineValue ?? json['value'] ?? json['equals'],
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'field': field,
        'operator': operator.name,
        if (value != null) 'value': value,
      };

  @override
  String toString() =>
      'FieldCondition(field: $field, op: $operator, value: $value)';
}

/// Combinable set of conditions with AND / OR logic.
@immutable
class FieldConditionGroup {
  /// Creates a [FieldConditionGroup].
  const FieldConditionGroup({
    this.conditions = const <FieldCondition>[],
    this.matchAll = true,
  });

  /// Individual conditions.
  final List<FieldCondition> conditions;

  /// When `true`, all conditions must pass (AND). Otherwise any (OR).
  final bool matchAll;

  /// Whether this group has any conditions.
  bool get isEmpty => conditions.isEmpty;

  /// Parses flexible JSON shapes into a group.
  ///
  /// Accepts:
  /// - a single condition map
  /// - `{ "all": [ ... ] }` / `{ "any": [ ... ] }`
  /// - a bare list of conditions
  factory FieldConditionGroup.fromJson(dynamic json) {
    if (json == null) {
      return const FieldConditionGroup();
    }

    if (json is List) {
      return FieldConditionGroup(
        conditions: json
            .map(
              (e) => FieldCondition.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
    }

    if (json is! Map) {
      throw ArgumentError('Condition group must be a Map or List');
    }

    final map = Map<String, dynamic>.from(json);

    if (map.containsKey('all') || map.containsKey('and')) {
      final list = (map['all'] ?? map['and']) as List;
      return FieldConditionGroup(
        conditions: list
            .map(
              (e) => FieldCondition.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
    }

    if (map.containsKey('any') || map.containsKey('or')) {
      final list = (map['any'] ?? map['or']) as List;
      return FieldConditionGroup(
        matchAll: false,
        conditions: list
            .map(
              (e) => FieldCondition.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
    }

    return FieldConditionGroup(
      conditions: [FieldCondition.fromJson(map)],
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() {
    if (conditions.isEmpty) return const <String, dynamic>{};
    if (conditions.length == 1 && matchAll) {
      return conditions.first.toJson();
    }
    return <String, dynamic>{
      matchAll ? 'all' : 'any':
          conditions.map((c) => c.toJson()).toList(),
    };
  }
}
