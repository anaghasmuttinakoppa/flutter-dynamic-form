import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_dynamic_form/json_dynamic_form.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DynamicFormExampleApp());
}

class DynamicFormExampleApp extends StatelessWidget {
  const DynamicFormExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'json_dynamic_form Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class DemoForm {
  const DemoForm({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
    this.useMediaPlugins = false,
    this.useCustomRenderer = false,
    this.useAsyncValidator = false,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final IconData icon;
  final bool useMediaPlugins;
  final bool useCustomRenderer;
  final bool useAsyncValidator;
}

const demos = <DemoForm>[
  DemoForm(
    title: 'Simple Form',
    subtitle: 'Name + email basics',
    assetPath: 'assets/schemas/simple_form.json',
    icon: Icons.short_text,
  ),
  DemoForm(
    title: 'Registration',
    subtitle: 'All Phase 1 field types',
    assetPath: 'assets/schemas/registration_form.json',
    icon: Icons.person_add_alt_1_outlined,
  ),
  DemoForm(
    title: 'Survey',
    subtitle: 'Validation + multiline feedback',
    assetPath: 'assets/schemas/survey_form.json',
    icon: Icons.rate_review_outlined,
  ),
  DemoForm(
    title: 'Selection & Dates',
    subtitle: 'Checkbox, switch, radio, dropdown, chips, pickers',
    assetPath: 'assets/schemas/selection_form.json',
    icon: Icons.tune,
  ),
  DemoForm(
    title: 'Conditional Form',
    subtitle: 'Show / enable fields from other answers',
    assetPath: 'assets/schemas/conditional_form.json',
    icon: Icons.alt_route,
  ),
  DemoForm(
    title: 'Nested Form',
    subtitle: 'Groups + compare password validation',
    assetPath: 'assets/schemas/nested_form.json',
    icon: Icons.account_tree_outlined,
  ),
  DemoForm(
    title: 'Media Upload',
    subtitle: 'Image, camera, file, location + async email',
    assetPath: 'assets/schemas/media_form.json',
    icon: Icons.cloud_upload_outlined,
    useMediaPlugins: true,
    useAsyncValidator: true,
  ),
  DemoForm(
    title: 'Advanced Controls',
    subtitle: 'Slider, rating, color, signature, repeatable, custom',
    assetPath: 'assets/schemas/advanced_form.json',
    icon: Icons.auto_awesome,
    useCustomRenderer: true,
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('json_dynamic_form'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            leading: Icon(demo.icon),
            title: Text(demo.title),
            subtitle: Text(demo.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FormDemoPage(demo: demo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FormDemoPage extends StatefulWidget {
  const FormDemoPage({super.key, required this.demo});

  final DemoForm demo;

  @override
  State<FormDemoPage> createState() => _FormDemoPageState();
}

class _FormDemoPageState extends State<FormDemoPage> {
  late final DynamicFormController _controller;
  late final DynamicFormPluginRegistry _plugins;
  Map<String, dynamic>? _schema;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = DynamicFormController();
    _plugins = DynamicFormPluginRegistry();

    if (widget.demo.useMediaPlugins) {
      _plugins.setMediaServices(mockMediaServices());
    }

    if (widget.demo.useCustomRenderer) {
      _plugins.registerRenderer('badge', (ctx) {
        return TextFormField(
          initialValue: ctx.controller.getValue(ctx.field.key)?.toString() ?? '',
          decoration: InputDecoration(
            labelText: ctx.field.label,
            hintText: ctx.field.effectivePlaceholder,
            prefixIcon: const Icon(Icons.badge_outlined),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ctx.theme.borderRadius),
            ),
          ),
          onChanged: (v) => ctx.controller.updateField(ctx.field.key, v),
        );
      });
    }

    if (widget.demo.useAsyncValidator) {
      _controller.registerAsyncValidator('uniqueEmail', (value, context) async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (value?.toString().toLowerCase() == 'taken@example.com') {
          return context.rule?.message ?? 'Email already registered';
        }
        return null;
      });
    }

    _loadSchema();
  }

  Future<void> _loadSchema() async {
    try {
      final raw = await rootBundle.loadString(widget.demo.assetPath);
      final decoded = jsonDecode(raw);
      setState(() {
        _schema = Map<String, dynamic>.from(decoded as Map);
        _loadError = null;
      });
    } catch (e) {
      setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showResult(Map<String, dynamic> values) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submitted values'),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(
              values.map((key, value) {
                if (value is MediaFileValue) return MapEntry(key, value.toJson());
                if (value is LocationValue) return MapEntry(key, value.toJson());
                return MapEntry(key, value);
              }),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.demo.title)),
      body: _loadError != null
          ? Center(child: Text('Failed to load schema:\n$_loadError'))
          : _schema == null
              ? const Center(child: CircularProgressIndicator())
              : DynamicForm(
                  json: _schema!,
                  controller: _controller,
                  plugins: _plugins,
                  theme: const DynamicFormTheme(
                    fieldSpacing: 18,
                    borderRadius: 12,
                    animateFields: true,
                    groupDecoration: true,
                  ),
                  onSubmit: (_) => _showResult(_controller.nestedValues),
                  onValidationFailed: (errors) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please fix ${errors.length} field'
                          '${errors.length == 1 ? '' : 's'}.',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
