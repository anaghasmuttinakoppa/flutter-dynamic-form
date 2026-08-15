import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DynamicFormController controller;
  late FormSchema schema;

  setUp(() {
    controller = DynamicFormController();
    schema = FormSchema.fromJson(<String, dynamic>{
      'title': 'Test',
      'fields': [
        {
          'type': 'text',
          'key': 'name',
          'label': 'Name',
          'required': true,
          'defaultValue': 'Ada',
        },
        {
          'type': 'email',
          'key': 'email',
          'label': 'Email',
          'required': true,
        },
        {
          'type': 'number',
          'key': 'age',
          'label': 'Age',
          'min': 18,
          'max': 99,
        },
      ],
    });
    controller.bind(schema);
  });

  tearDown(() => controller.dispose());

  test('bind seeds default values', () {
    expect(controller.values['name'], 'Ada');
    expect(controller.values['email'], isNull);
    expect(controller.isDirty, isFalse);
  });

  test('updateField mutates values and marks dirty', () {
    controller.updateField('name', 'Grace', validate: false);
    expect(controller.values['name'], 'Grace');
    expect(controller.isDirty, isTrue);
  });

  test('validate fails for missing required fields', () {
    controller.updateField('name', '', validate: false);
    expect(controller.validate(), isFalse);
    expect(controller.errors.containsKey('name'), isTrue);
    expect(controller.errors.containsKey('email'), isTrue);
  });

  test('validate succeeds for valid payload', () {
    controller.patchValues(<String, dynamic>{
      'name': 'Grace Hopper',
      'email': 'grace@example.com',
      'age': 40,
    });
    expect(controller.validate(), isTrue);
    expect(controller.errors, isEmpty);
  });

  test('submit invokes callbacks only when valid', () async {
    var submitted = false;
    controller.onSubmit = (_) => submitted = true;

    expect(await controller.submit(), isFalse);
    expect(submitted, isFalse);

    controller.patchValues(<String, dynamic>{
      'name': 'Grace Hopper',
      'email': 'grace@example.com',
    });
    expect(await controller.submit(), isTrue);
    expect(submitted, isTrue);
  });

  test('reset restores defaults', () {
    controller.updateField('name', 'Changed', validate: false);
    controller.reset();
    expect(controller.values['name'], 'Ada');
    expect(controller.isDirty, isFalse);
    expect(controller.errors, isEmpty);
  });

  test('clear nulls values', () {
    controller.clear();
    expect(controller.values['name'], isNull);
    expect(controller.values['email'], isNull);
  });

  test('patchValues updates multiple keys', () {
    controller.patchValues(<String, dynamic>{
      'email': 'a@b.co',
      'age': 22,
    });
    expect(controller.values['email'], 'a@b.co');
    expect(controller.values['age'], 22);
  });

  test('onFieldChanged fires', () {
    String? changedKey;
    dynamic changedValue;
    controller.onFieldChanged = (key, value) {
      changedKey = key;
      changedValue = value;
    };
    controller.updateField('age', 30, validate: false);
    expect(changedKey, 'age');
    expect(changedValue, 30);
  });
}
