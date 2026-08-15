import 'package:flutter/material.dart';
import 'package:json_dynamic_form/json_dynamic_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('media fields render and mock pickers work', (tester) async {
    final controller = DynamicFormController();
    final plugins = DynamicFormPluginRegistry(
      mediaServices: mockMediaServices(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            controller: controller,
            plugins: plugins,
            json: const {
              'fields': [
                {'type': 'image', 'key': 'avatar', 'label': 'Avatar'},
                {'type': 'location', 'key': 'loc', 'label': 'Location'},
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('Avatar'), findsOneWidget);
    expect(find.text('Pick image'), findsOneWidget);

    await tester.tap(find.text('Pick image'));
    await tester.pumpAndSettle();
    expect(controller.getValue('avatar'), isA<MediaFileValue>());

    await tester.tap(find.text('Get location'));
    await tester.pumpAndSettle();
    expect(controller.getValue('loc'), isA<LocationValue>());

    controller.dispose();
  });

  testWidgets('custom renderer is used', (tester) async {
    final plugins = DynamicFormPluginRegistry();
    plugins.registerRenderer('badge', (ctx) {
      return Text('CUSTOM_BADGE_${ctx.field.key}');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            plugins: plugins,
            json: const {
              'fields': [
                {
                  'type': 'custom',
                  'customType': 'badge',
                  'key': 'code',
                  'label': 'Code',
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('CUSTOM_BADGE_code'), findsOneWidget);
  });

  testWidgets('repeatable add item', (tester) async {
    final controller = DynamicFormController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'repeatable',
                  'key': 'refs',
                  'label': 'References',
                  'fields': [
                    {'type': 'text', 'key': 'name', 'label': 'Name'},
                  ],
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('Add item'), findsOneWidget);
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Name'), findsWidgets);

    controller.dispose();
  });

  testWidgets('slider and rating render', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DynamicForm(
            json: {
              'fields': [
                {
                  'type': 'slider',
                  'key': 'vol',
                  'label': 'Volume',
                  'min': 0,
                  'max': 10,
                  'defaultValue': 5,
                },
                {
                  'type': 'rating',
                  'key': 'stars',
                  'label': 'Stars',
                  'max': 5,
                },
              ],
            },
          ),
        ),
      ),
    );

    expect(find.text('Volume'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Stars'), findsOneWidget);
  });
}
