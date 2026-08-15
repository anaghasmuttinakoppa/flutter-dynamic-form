import '../core/enums.dart';
import '../models/field_condition.dart';

/// Evaluates [FieldCondition] / [FieldConditionGroup] against form values.
class ConditionEvaluator {
  /// Creates a [ConditionEvaluator].
  const ConditionEvaluator();

  /// Returns whether [group] is satisfied by [values].
  ///
  /// An empty group is always satisfied.
  bool evaluateGroup(
    FieldConditionGroup? group,
    Map<String, dynamic> values,
  ) {
    if (group == null || group.isEmpty) return true;
    if (group.matchAll) {
      return group.conditions.every((c) => evaluate(c, values));
    }
    return group.conditions.any((c) => evaluate(c, values));
  }

  /// Returns whether a single [condition] is satisfied by [values].
  bool evaluate(FieldCondition condition, Map<String, dynamic> values) {
    final actual = values[condition.field];
    final expected = condition.value;

    switch (condition.operator) {
      case ConditionOperator.equals:
        return _equals(actual, expected);
      case ConditionOperator.notEquals:
        return !_equals(actual, expected);
      case ConditionOperator.greaterThan:
        return _compare(actual, expected) > 0;
      case ConditionOperator.greaterThanOrEqual:
        return _compare(actual, expected) >= 0;
      case ConditionOperator.lessThan:
        return _compare(actual, expected) < 0;
      case ConditionOperator.lessThanOrEqual:
        return _compare(actual, expected) <= 0;
      case ConditionOperator.contains:
        return _contains(actual, expected);
      case ConditionOperator.isEmpty:
        return _isEmpty(actual);
      case ConditionOperator.isNotEmpty:
        return !_isEmpty(actual);
      case ConditionOperator.isIn:
        if (expected is Iterable) {
          return expected.any((e) => _equals(actual, e));
        }
        return false;
    }
  }

  bool _equals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a is num && b is num) return a == b;
    return a.toString() == b.toString();
  }

  int _compare(dynamic a, dynamic b) {
    final an = _asNum(a);
    final bn = _asNum(b);
    if (an != null && bn != null) {
      return an.compareTo(bn);
    }
    return a.toString().compareTo(b.toString());
  }

  bool _contains(dynamic actual, dynamic expected) {
    if (actual == null) return false;
    if (actual is String) {
      return actual.contains(expected?.toString() ?? '');
    }
    if (actual is Iterable) {
      return actual.any((e) => _equals(e, expected));
    }
    return actual.toString().contains(expected?.toString() ?? '');
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is bool) return !value;
    return false;
  }

  num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().trim());
  }
}
