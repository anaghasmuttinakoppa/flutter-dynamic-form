import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = ConditionEvaluator();

  group('ConditionEvaluator', () {
    test('equals / notEquals', () {
      final values = <String, dynamic>{'country': 'India'};
      expect(
        evaluator.evaluate(
          const FieldCondition(
            field: 'country',
            value: 'India',
          ),
          values,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          const FieldCondition(
            field: 'country',
            operator: ConditionOperator.notEquals,
            value: 'India',
          ),
          values,
        ),
        isFalse,
      );
    });

    test('numeric comparisons', () {
      final values = <String, dynamic>{'age': 16};
      expect(
        evaluator.evaluate(
          const FieldCondition(
            field: 'age',
            operator: ConditionOperator.lessThan,
            value: 18,
          ),
          values,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          const FieldCondition(
            field: 'age',
            operator: ConditionOperator.greaterThanOrEqual,
            value: 18,
          ),
          values,
        ),
        isFalse,
      );
    });

    test('contains and isIn', () {
      final values = <String, dynamic>{
        'tags': <String>['a', 'b'],
        'role': 'admin',
      };
      expect(
        evaluator.evaluate(
          const FieldCondition(
            field: 'tags',
            operator: ConditionOperator.contains,
            value: 'b',
          ),
          values,
        ),
        isTrue,
      );
      expect(
        evaluator.evaluate(
          const FieldCondition(
            field: 'role',
            operator: ConditionOperator.isIn,
            value: ['admin', 'editor'],
          ),
          values,
        ),
        isTrue,
      );
    });

    test('group all / any', () {
      final values = <String, dynamic>{'age': 20, 'accept': true};
      final all = FieldConditionGroup.fromJson({
        'all': [
          {'field': 'age', 'op': 'gte', 'value': 18},
          {'field': 'accept', 'operator': 'equals', 'value': true},
        ],
      });
      expect(evaluator.evaluateGroup(all, values), isTrue);

      final any = FieldConditionGroup.fromJson({
        'any': [
          {'field': 'age', 'op': 'lt', 'value': 10},
          {'field': 'accept', 'operator': 'equals', 'value': true},
        ],
      });
      expect(evaluator.evaluateGroup(any, values), isTrue);
    });
  });
}
