/// A production-ready Flutter package that generates fully dynamic forms
/// from JSON schemas.
///
/// ## Quick start
///
/// ```dart
/// final controller = DynamicFormController();
///
/// DynamicForm(
///   json: {
///     'title': 'User Registration',
///     'fields': [
///       {'type': 'text', 'key': 'name', 'label': 'Full Name', 'required': true},
///       {'type': 'email', 'key': 'email', 'required': true},
///       {'type': 'number', 'key': 'age'},
///     ],
///   },
///   controller: controller,
///   onSubmit: (values) => print(values),
/// );
/// ```
library;

export 'src/conditions/condition_evaluator.dart';
export 'src/controllers/dynamic_form_controller.dart';
export 'src/core/enums.dart';
export 'src/core/exceptions.dart';
export 'src/l10n/dynamic_form_localizations.dart';
export 'src/models/field_condition.dart';
export 'src/models/field_option.dart';
export 'src/models/form_field_schema.dart';
export 'src/models/form_schema.dart';
export 'src/models/media_value.dart';
export 'src/models/schema_validation_issue.dart';
export 'src/models/validation_rule.dart';
export 'src/parsers/form_schema_parser.dart';
export 'src/parsers/form_schema_validator.dart';
export 'src/plugins/mock_media_services.dart';
export 'src/plugins/plugin_registry.dart';
export 'src/theme/dynamic_form_theme.dart';
export 'src/validators/field_validator.dart';
export 'src/validators/validators.dart';
export 'src/widgets/dynamic_form.dart';
export 'src/widgets/schema_error_view.dart';
