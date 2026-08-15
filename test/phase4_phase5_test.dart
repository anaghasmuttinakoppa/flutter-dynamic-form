import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 async validators', () {
    late DynamicFormController controller;

    setUp(() {
      controller = DynamicFormController();
      controller.bind(
        FormSchema.fromJson({
          'fields': [
            {
              'type': 'email',
              'key': 'email',
              'required': true,
              'validators': [
                {'type': 'async', 'name': 'uniqueEmail'},
              ],
            },
          ],
        }),
      );
      controller.registerAsyncValidator('uniqueEmail', (value, context) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (value == 'taken@example.com') return 'Taken';
        return null;
      });
    });

    tearDown(() => controller.dispose());

    test('validateAsync fails for taken email', () async {
      controller.updateField('email', 'taken@example.com', validate: false);
      expect(await controller.validateAsync(), isFalse);
      expect(controller.errors['email'], 'Taken');
    });

    test('validateAsync passes for free email', () async {
      controller.updateField('email', 'free@example.com', validate: false);
      expect(await controller.validateAsync(), isTrue);
      expect(controller.errors, isEmpty);
    });

    test('server validator is invoked', () async {
      controller.setServerValidator((value, context, rule) async {
        if (rule.url == '/check' && value == 'bad') return 'Rejected';
        return null;
      });
      controller.bind(
        FormSchema.fromJson({
          'fields': [
            {
              'type': 'text',
              'key': 'code',
              'validators': [
                {'type': 'server', 'url': '/check'},
              ],
            },
          ],
        }),
      );
      controller.updateField('code', 'bad', validate: false);
      expect(await controller.validateAsync(), isFalse);
      expect(controller.errors['code'], 'Rejected');
    });
  });

  group('Phase 4 media parsing', () {
    test('parses media field types', () {
      final schema = FormSchema.fromJson({
        'fields': [
          {'type': 'image', 'key': 'avatar'},
          {'type': 'camera', 'key': 'shot'},
          {'type': 'file', 'key': 'doc', 'allowedExtensions': ['pdf']},
          {'type': 'location', 'key': 'loc'},
        ],
      });
      expect(schema.fields.map((f) => f.type), [
        FieldType.image,
        FieldType.camera,
        FieldType.file,
        FieldType.location,
      ]);
      expect(schema.fields[2].allowedExtensions, ['pdf']);
    });

    test('MediaFileValue / LocationValue round-trip', () {
      final media = MediaFileValue.fromJson({
        'path': '/tmp/a.jpg',
        'name': 'a.jpg',
        'source': 'gallery',
      });
      expect(media.toJson()['name'], 'a.jpg');

      final loc = LocationValue.fromJson({
        'lat': 1.23,
        'lng': 4.56,
        'address': 'Somewhere',
      });
      expect(loc.latitude, 1.23);
      expect(loc.toJson()['address'], 'Somewhere');
    });
  });

  group('Phase 5 repeatable + plugin', () {
    test('repeatable add/remove items', () {
      final controller = DynamicFormController();
      controller.bind(
        FormSchema.fromJson({
          'fields': [
            {
              'type': 'repeatable',
              'key': 'people',
              'minItems': 0,
              'maxItems': 2,
              'fields': [
                {'type': 'text', 'key': 'name'},
              ],
            },
          ],
        }),
      );

      expect(controller.getValue('people'), isEmpty);
      controller.addRepeatableItem('people');
      expect((controller.getValue('people') as List).length, 1);
      controller.updateRepeatableItemField('people', 0, 'name', 'Ada');
      expect((controller.getValue('people') as List).first['name'], 'Ada');
      controller.addRepeatableItem('people');
      controller.addRepeatableItem('people'); // capped at 2
      expect((controller.getValue('people') as List).length, 2);
      controller.removeRepeatableItem('people', 0);
      expect((controller.getValue('people') as List).length, 1);
      controller.dispose();
    });

    test('parses advanced field types', () {
      final schema = FormSchema.fromJson({
        'fields': [
          {'type': 'slider', 'key': 'vol', 'min': 0, 'max': 10},
          {'type': 'range_slider', 'key': 'range'},
          {'type': 'rating', 'key': 'stars'},
          {'type': 'signature', 'key': 'sig'},
          {'type': 'color', 'key': 'color'},
          {
            'type': 'custom',
            'customType': 'badge',
            'key': 'badge',
          },
        ],
      });
      expect(schema.fields[0].type, FieldType.slider);
      expect(schema.fields[1].type, FieldType.rangeSlider);
      expect(schema.fields[5].customType, 'badge');
    });
  });
}
