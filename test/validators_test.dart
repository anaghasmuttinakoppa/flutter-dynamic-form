import 'package:json_dynamic_form/json_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

FormFieldSchema _field({
  required String key,
  FieldType type = FieldType.text,
  bool required = false,
  List<ValidationRule> validators = const [],
  String? label,
  num? min,
  num? max,
}) {
  return FormFieldSchema(
    key: key,
    type: type,
    label: label ?? key,
    required: required,
    min: min,
    max: max,
    validators: validators,
  );
}

void main() {
  group('Validators', () {
    final contextField = _field(key: 'name', label: 'Name');

    ValidationContext ctx([FormFieldSchema? field, ValidationRule? rule]) {
      return ValidationContext(
        field: field ?? contextField,
        values: const <String, dynamic>{},
        rule: rule,
      );
    }

    test('required rejects empty values', () {
      final v = Validators.required();
      expect(v(null, ctx()), isNotNull);
      expect(v('', ctx()), isNotNull);
      expect(v('  ', ctx()), isNotNull);
      expect(v('Ada', ctx()), isNull);
    });

    test('email validates format', () {
      final v = Validators.email();
      expect(v('not-an-email', ctx()), isNotNull);
      expect(v('ada@lovelace.dev', ctx()), isNull);
      expect(v(null, ctx()), isNull);
    });

    test('phone validates format', () {
      final v = Validators.phone();
      expect(v('123', ctx()), isNotNull);
      expect(v('+1 (555) 010-2030', ctx()), isNull);
    });

    test('regex validates pattern', () {
      final v = Validators.regex(r'^\d{4}$');
      expect(v('12', ctx()), isNotNull);
      expect(v('1234', ctx()), isNull);
    });

    test('length enforces min and max', () {
      final v = Validators.length(min: 2, max: 5);
      expect(v('a', ctx()), isNotNull);
      expect(v('abc', ctx()), isNull);
      expect(v('abcdef', ctx()), isNotNull);
    });

    test('min and max enforce numeric bounds', () {
      expect(Validators.min(18)(17, ctx()), isNotNull);
      expect(Validators.min(18)(18, ctx()), isNull);
      expect(Validators.max(100)(101, ctx()), isNotNull);
      expect(Validators.max(100)(99, ctx()), isNull);
    });

    test('validateField runs rule chain', () {
      final field = _field(
        key: 'email',
        type: FieldType.email,
        label: 'Email',
        validators: const [
          ValidationRule(type: ValidatorType.required),
          ValidationRule(type: ValidatorType.email),
        ],
      );

      expect(
        Validators.validateField(
          field: field,
          value: '',
          values: const {},
        ),
        contains('required'),
      );

      expect(
        Validators.validateField(
          field: field,
          value: 'bad',
          values: const {},
        ),
        contains('email'),
      );

      expect(
        Validators.validateField(
          field: field,
          value: 'ok@example.com',
          values: const {},
        ),
        isNull,
      );
    });
  });
}
