import 'package:flutter/material.dart';

import '../builders/field_builder.dart';
import '../controllers/dynamic_form_controller.dart';
import '../l10n/dynamic_form_localizations.dart';
import '../models/form_schema.dart';
import '../models/schema_validation_issue.dart';
import '../parsers/form_schema_parser.dart';
import '../parsers/form_schema_validator.dart';
import '../plugins/plugin_registry.dart';
import '../theme/dynamic_form_theme.dart';
import 'schema_error_view.dart';

/// Renders a complete form from a JSON schema (or [FormSchema]).
///
/// Schema JSON is validated **before** the form is built. If validation fails,
/// a [SchemaErrorView] is shown instead of the form, with JSON paths for each
/// issue.
///
/// ```dart
/// DynamicForm(
///   json: schemaMap,
///   controller: controller,
///   onSubmit: (values) => print(values),
/// );
/// ```
class DynamicForm extends StatefulWidget {
  /// Creates a [DynamicForm] from a JSON [Map], JSON [String], or [FormSchema].
  const DynamicForm({
    super.key,
    required this.json,
    this.controller,
    this.theme,
    this.localizations,
    this.plugins,
    this.padding = const EdgeInsets.all(16),
    this.showSubmitButton = true,
    this.showResetButton,
    this.submitLabel,
    this.resetLabel,
    this.onSubmit,
    this.onChanged,
    this.onFieldChanged,
    this.onValidationFailed,
    this.onValidationSuccess,
    this.onSaved,
    this.onSchemaInvalid,
    this.fieldBuilder = const FieldBuilder(),
    this.scrollable = true,
    this.validateSchema = true,
    this.useSafeArea = true,
  });

  /// Schema source: [Map], JSON [String], or [FormSchema].
  final Object json;

  /// Optional external controller. If omitted, one is created internally.
  final DynamicFormController? controller;

  /// Visual customization.
  final DynamicFormTheme? theme;

  /// Optional localized strings.
  final DynamicFormLocalizations? localizations;

  /// Optional plugin registry (custom renderers + media services).
  final DynamicFormPluginRegistry? plugins;

  /// Outer padding around the form.
  final EdgeInsetsGeometry padding;

  /// Whether to show the submit button.
  final bool showSubmitButton;

  /// Whether to show the reset button (falls back to theme).
  final bool? showResetButton;

  /// Override submit button label.
  final String? submitLabel;

  /// Override reset button label.
  final String? resetLabel;

  /// Called with form values after a successful submit.
  final void Function(Map<String, dynamic> values)? onSubmit;

  /// Called whenever values change.
  final void Function(Map<String, dynamic> values)? onChanged;

  /// Called when a single field changes.
  final void Function(String key, dynamic value)? onFieldChanged;

  /// Called when validation fails.
  final void Function(Map<String, String> errors)? onValidationFailed;

  /// Called when validation succeeds.
  final void Function(Map<String, dynamic> values)? onValidationSuccess;

  /// Called after values are saved on submit.
  final void Function(Map<String, dynamic> values)? onSaved;

  /// Called when schema JSON validation fails (before form render).
  final void Function(SchemaValidationResult result)? onSchemaInvalid;

  /// Strategy used to build field widgets.
  final FieldBuilder fieldBuilder;

  /// Whether the form body is wrapped in a scroll view.
  final bool scrollable;

  /// When `true` (default), validates schema JSON before rendering.
  final bool validateSchema;

  /// Wraps content in [SafeArea] for notches / system UI.
  final bool useSafeArea;

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  static const FormSchemaParser _parser = FormSchemaParser();
  static const FormSchemaValidator _validator = FormSchemaValidator();

  late DynamicFormController _controller;
  FormSchema? _schema;
  late bool _ownsController;
  late DynamicFormPluginRegistry _plugins;
  SchemaValidationResult? _schemaValidation;
  Object? _parseError;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? DynamicFormController();
    _plugins = widget.plugins ?? DynamicFormPluginRegistry();
    _wireCallbacks();
    _parseAndBind(resetValues: true);
  }

  @override
  void didUpdateWidget(covariant DynamicForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.plugins != widget.plugins && widget.plugins != null) {
      _plugins = widget.plugins!;
    }

    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? DynamicFormController();
      _wireCallbacks();
      _parseAndBind(resetValues: true);
      return;
    }

    if (oldWidget.json != widget.json ||
        oldWidget.validateSchema != widget.validateSchema) {
      _parseAndBind(resetValues: true);
    } else {
      _wireCallbacks();
    }
  }

  void _wireCallbacks() {
    _controller
      ..onSubmit = widget.onSubmit
      ..onChanged = widget.onChanged
      ..onFieldChanged = widget.onFieldChanged
      ..onValidationFailed = widget.onValidationFailed
      ..onValidationSuccess = widget.onValidationSuccess
      ..onSaved = widget.onSaved;
  }

  void _parseAndBind({required bool resetValues}) {
    _schemaValidation = null;
    _parseError = null;
    _schema = null;

    // Already-parsed schema skips JSON structure validation.
    if (widget.json is FormSchema) {
      _schema = widget.json as FormSchema;
      _controller.bind(_schema!, resetValues: resetValues);
      return;
    }

    if (widget.validateSchema) {
      final result = _validator.validate(widget.json);
      if (!result.isValid) {
        _schemaValidation = result;
        widget.onSchemaInvalid?.call(result);
        return;
      }
      // Keep warnings available for optional display after successful parse.
      if (result.warnings.isNotEmpty) {
        _schemaValidation = result;
      }
    }

    try {
      _schema = _parser.parse(widget.json);
      _controller.bind(_schema!, resetValues: resetValues);
    } catch (e) {
      _parseError = e;
      _schemaValidation = SchemaValidationResult(
        issues: [
          SchemaValidationIssue(
            path: r'$',
            message: e.toString(),
          ),
        ],
      );
      widget.onSchemaInvalid?.call(_schemaValidation!);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = DynamicFormTheme.resolve(context, widget.theme);
    final l10n = widget.localizations ?? DynamicFormLocalizations.en;

    Widget child;
    if (_schemaValidation != null && !_schemaValidation!.isValid) {
      child = SchemaErrorView(
        result: _schemaValidation!,
        padding: widget.padding,
      );
    } else if (_parseError != null) {
      child = SchemaErrorView(
        result: SchemaValidationResult(
          issues: [
            SchemaValidationIssue(
              path: r'$',
              message: _parseError.toString(),
            ),
          ],
        ),
        padding: widget.padding,
      );
    } else if (_schema == null) {
      child = Padding(
        padding: widget.padding,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else {
      child = DynamicFormThemeProvider(
        theme: theme,
        child: DynamicFormLocalizationsProvider(
          localizations: l10n,
          child: DynamicFormPlugins(
            registry: _plugins,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final body = _buildBody(context, theme);
                if (!widget.scrollable) return body;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: body,
                );
              },
            ),
          ),
        ),
      );
    }

    child = _constrainWidth(context, theme, child);

    if (widget.useSafeArea) {
      child = SafeArea(child: child);
    }

    return child;
  }

  Widget _constrainWidth(
    BuildContext context,
    DynamicFormTheme theme,
    Widget child,
  ) {
    final maxWidth = theme.maxContentWidth;
    if (maxWidth == null) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= maxWidth) return child;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DynamicFormTheme theme) {
    final materialTheme = Theme.of(context);
    final showReset = widget.showResetButton ?? theme.showResetButton;
    final schema = _schema!;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_schemaValidation != null &&
              _schemaValidation!.isValid &&
              _schemaValidation!.warnings.isNotEmpty)
            _WarningsBanner(result: _schemaValidation!),
          if (schema.title != null) ...[
            Text(
              schema.title!,
              style: theme.titleStyle ??
                  materialTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          if (schema.description != null) ...[
            Text(
              schema.description!,
              style: theme.descriptionStyle ??
                  materialTheme.textTheme.bodyMedium?.copyWith(
                    color: materialTheme.colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: theme.fieldSpacing),
          ],
          for (final field in schema.fields) ...[
            widget.fieldBuilder.build(
              context: context,
              field: field,
              controller: _controller,
              theme: theme,
            ),
            if (_controller.isFieldVisible(field))
              SizedBox(height: theme.fieldSpacing),
          ],
          if (widget.showSubmitButton || showReset)
            _buildActions(theme, showReset, schema),
        ],
      ),
    );
  }

  Widget _buildActions(
    DynamicFormTheme theme,
    bool showReset,
    FormSchema schema,
  ) {
    final submitLabel = widget.submitLabel ?? schema.submitLabel;
    final resetLabel = widget.resetLabel ?? schema.resetLabel;
    final busy = _controller.isSubmitting || _controller.isValidating;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 360;
        final resetBtn = OutlinedButton(
          style: theme.resetButtonStyle,
          onPressed: busy ? null : _controller.reset,
          child: Text(resetLabel),
        );
        final submitBtn = FilledButton(
          style: theme.submitButtonStyle,
          onPressed: busy
              ? null
              : () {
                  _controller.submit();
                },
          child: busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showSubmitButton) submitBtn,
              if (widget.showSubmitButton && showReset)
                const SizedBox(height: 8),
              if (showReset) resetBtn,
            ],
          );
        }

        return Row(
          children: [
            if (showReset) Expanded(child: resetBtn),
            if (showReset && widget.showSubmitButton) const SizedBox(width: 12),
            if (widget.showSubmitButton) Expanded(child: submitBtn),
          ],
        );
      },
    );
  }
}

class _WarningsBanner extends StatelessWidget {
  const _WarningsBanner({required this.result});

  final SchemaValidationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schema warnings (${result.warnings.length})',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...result.warnings.take(5).map(
                    (w) => Text(
                      '• ${w.path}: ${w.message}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
