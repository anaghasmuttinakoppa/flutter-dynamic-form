import 'package:flutter/foundation.dart';

import '../conditions/condition_evaluator.dart';
import '../core/enums.dart';
import '../models/form_field_schema.dart';
import '../models/form_schema.dart';
import '../models/media_value.dart';
import '../models/validation_rule.dart';
import '../validators/field_validator.dart';
import '../validators/validators.dart';

/// Snapshot of form state exposed to listeners.
@immutable
class DynamicFormState {
  /// Creates a [DynamicFormState].
  const DynamicFormState({
    required this.values,
    required this.errors,
    required this.isValid,
    required this.isDirty,
    required this.isSubmitting,
    required this.isValidating,
  });

  /// Current field values keyed by field key.
  final Map<String, dynamic> values;

  /// Current field errors keyed by field key.
  final Map<String, String> errors;

  /// Whether the form currently has no errors.
  final bool isValid;

  /// Whether any field has been modified since last reset.
  final bool isDirty;

  /// Whether a submit is in progress.
  final bool isSubmitting;

  /// Whether async validation is running.
  final bool isValidating;

  /// Empty initial state.
  factory DynamicFormState.empty() => const DynamicFormState(
        values: <String, dynamic>{},
        errors: <String, String>{},
        isValid: true,
        isDirty: false,
        isSubmitting: false,
        isValidating: false,
      );

  @override
  String toString() =>
      'DynamicFormState(isValid: $isValid, isDirty: $isDirty, '
      'values: $values, errors: $errors)';
}

/// Signature for a server validator that receives optional URL metadata.
typedef ServerFieldValidator = Future<String?> Function(
  dynamic value,
  ValidationContext context,
  ValidationRule rule,
);

/// Controls values, validation, and events for a [FormSchema]-driven form.
class DynamicFormController extends ChangeNotifier {
  /// Creates a [DynamicFormController].
  DynamicFormController({
    Map<String, FieldValidator>? customValidators,
    Map<String, AsyncFieldValidator>? asyncValidators,
    ServerFieldValidator? serverValidator,
    ConditionEvaluator conditionEvaluator = const ConditionEvaluator(),
  })  : _customValidators = customValidators ?? <String, FieldValidator>{},
        _asyncValidators =
            asyncValidators ?? <String, AsyncFieldValidator>{},
        _serverValidator = serverValidator,
        _conditionEvaluator = conditionEvaluator;

  FormSchema? _schema;
  final Map<String, dynamic> _values = <String, dynamic>{};
  final Map<String, String> _errors = <String, String>{};
  final Map<String, FieldValidator> _customValidators;
  final Map<String, AsyncFieldValidator> _asyncValidators;
  ServerFieldValidator? _serverValidator;
  final ConditionEvaluator _conditionEvaluator;
  bool _isDirty = false;
  bool _isSubmitting = false;
  bool _isValidating = false;
  bool _disposed = false;

  /// Called after a successful [submit] when validation passes.
  void Function(Map<String, dynamic> values)? onSubmit;

  /// Called when any field value changes.
  void Function(String key, dynamic value)? onFieldChanged;

  /// Called when the full values map changes.
  void Function(Map<String, dynamic> values)? onChanged;

  /// Called when validation fails.
  void Function(Map<String, String> errors)? onValidationFailed;

  /// Called when validation succeeds.
  void Function(Map<String, dynamic> values)? onValidationSuccess;

  /// Called after values are saved / collected (alias of successful submit).
  void Function(Map<String, dynamic> values)? onSaved;

  /// Bound schema (set by [DynamicForm] or manually via [bind]).
  FormSchema? get schema => _schema;

  /// Immutable copy of current values.
  Map<String, dynamic> get values => Map<String, dynamic>.unmodifiable(_values);

  /// Nested values: group children nested under the group key.
  Map<String, dynamic> get nestedValues {
    final schema = _schema;
    if (schema == null) return values;
    return Map<String, dynamic>.unmodifiable(_buildNested(schema.fields));
  }

  /// Immutable copy of current errors.
  Map<String, String> get errors => Map<String, String>.unmodifiable(_errors);

  /// Whether there are currently no validation errors.
  bool get isValid => _errors.isEmpty;

  /// Whether any value changed since bind / reset.
  bool get isDirty => _isDirty;

  /// Whether [submit] is running.
  bool get isSubmitting => _isSubmitting;

  /// Whether async validation is running.
  bool get isValidating => _isValidating;

  /// Combined state snapshot.
  DynamicFormState get state => DynamicFormState(
        values: values,
        errors: errors,
        isValid: isValid,
        isDirty: _isDirty,
        isSubmitting: _isSubmitting,
        isValidating: _isValidating,
      );

  /// Binds a schema and seeds default values.
  void bind(FormSchema schema, {bool resetValues = true}) {
    _ensureNotDisposed();
    _schema = schema;
    if (resetValues) {
      _values.clear();
      _errors.clear();
      _isDirty = false;
      _seedDefaults(schema.fields);
    } else {
      for (final field in schema.leafFields) {
        _values.putIfAbsent(field.key, () => field.defaultValue);
      }
    }
    _notify();
  }

  /// Returns the value for [key].
  dynamic getValue(String key) => _values[key];

  /// Whether [field] is currently visible given schema + conditions.
  bool isFieldVisible(FormFieldSchema field) {
    if (!field.visible) return false;
    return _conditionEvaluator.evaluateGroup(field.visibleWhen, _values);
  }

  /// Whether [field] is currently enabled given schema + conditions.
  bool isFieldEnabled(FormFieldSchema field) {
    if (!field.enabled) return false;
    if (field.readOnly) return false;
    return _conditionEvaluator.evaluateGroup(field.enabledWhen, _values);
  }

  /// Convenience: visibility by key.
  bool isVisible(String key) {
    final field = fieldFor(key);
    if (field == null) return false;
    return isFieldVisible(field);
  }

  /// Convenience: enabled by key.
  bool isEnabled(String key) {
    final field = fieldFor(key);
    if (field == null) return false;
    return isFieldEnabled(field);
  }

  /// Updates a single field and optionally validates it (sync rules only).
  void updateField(
    String key,
    dynamic value, {
    bool validate = true,
    bool notifyListeners = true,
  }) {
    _ensureNotDisposed();
    if (_values[key] == value) return;

    if (_values[key] is List && value is List) {
      final a = _values[key] as List;
      if (a.length == value.length &&
          List.generate(a.length, (i) => a[i] == value[i]).every((e) => e)) {
        return;
      }
    }

    _values[key] = value;
    _isDirty = true;
    onFieldChanged?.call(key, value);
    onChanged?.call(values);
    _pruneHiddenErrors();

    if (validate) {
      validateField(key, notify: false);
    }

    if (notifyListeners) {
      _notify();
    }
  }

  /// Patches multiple values at once.
  void patchValues(
    Map<String, dynamic> patch, {
    bool validate = false,
  }) {
    _ensureNotDisposed();
    var changed = false;
    patch.forEach((key, value) {
      if (_values[key] != value) {
        _values[key] = value;
        changed = true;
        onFieldChanged?.call(key, value);
      }
    });
    if (!changed) return;
    _isDirty = true;
    onChanged?.call(values);
    _pruneHiddenErrors();
    if (validate) {
      this.validate(notify: false);
    }
    _notify();
  }

  /// Appends an item to a [FieldType.repeatable] field.
  void addRepeatableItem(String key, {Map<String, dynamic>? values}) {
    final field = fieldFor(key);
    if (field == null || !field.isRepeatable) return;
    final list = List<Map<String, dynamic>>.from(
      (_values[key] as List?)?.map(
            (e) => Map<String, dynamic>.from(e as Map),
          ) ??
          const <Map<String, dynamic>>[],
    );
    if (field.maxItems != null && list.length >= field.maxItems!) return;

    final item = <String, dynamic>{};
    for (final child in field.fields) {
      item[child.key] = values?[child.key] ?? child.defaultValue;
    }
    list.add(item);
    updateField(key, list);
  }

  /// Removes a repeatable item at [index].
  void removeRepeatableItem(String key, int index) {
    final field = fieldFor(key);
    if (field == null || !field.isRepeatable) return;
    final list = List<Map<String, dynamic>>.from(
      (_values[key] as List?)?.map(
            (e) => Map<String, dynamic>.from(e as Map),
          ) ??
          const <Map<String, dynamic>>[],
    );
    if (index < 0 || index >= list.length) return;
    if (field.minItems != null && list.length <= field.minItems!) return;
    list.removeAt(index);
    updateField(key, list);
  }

  /// Updates a nested value inside a repeatable item.
  void updateRepeatableItemField(
    String key,
    int index,
    String childKey,
    dynamic value,
  ) {
    final list = List<Map<String, dynamic>>.from(
      (_values[key] as List?)?.map(
            (e) => Map<String, dynamic>.from(e as Map),
          ) ??
          const <Map<String, dynamic>>[],
    );
    if (index < 0 || index >= list.length) return;
    list[index] = Map<String, dynamic>.from(list[index])..[childKey] = value;
    updateField(key, list);
  }

  /// Validates a single field synchronously (skips async/server rules).
  bool validateField(String key, {bool notify = true}) {
    _ensureNotDisposed();
    final schema = _schema;
    if (schema == null) return true;

    final field = schema.fieldByKey(key);
    if (field == null || field.isGroup) return true;
    if (!isFieldVisible(field)) {
      _errors.remove(key);
      if (notify) _notify();
      return true;
    }

    final error = _validateSync(field, _values[key]);
    if (error == null) {
      _errors.remove(key);
    } else {
      _errors[key] = error;
    }

    if (notify) _notify();
    return error == null;
  }

  /// Validates all visible leaf fields synchronously.
  bool validate({bool notify = true}) {
    _ensureNotDisposed();
    final schema = _schema;
    if (schema == null) return true;

    _errors.clear();
    for (final field in schema.leafFields) {
      if (!isFieldVisible(field)) continue;
      final error = _validateSync(field, _values[field.key]);
      if (error != null) {
        _errors[field.key] = error;
      }
    }

    final ok = _errors.isEmpty;
    if (ok) {
      onValidationSuccess?.call(values);
    } else {
      onValidationFailed?.call(errors);
    }

    if (notify) _notify();
    return ok;
  }

  /// Runs sync + async/server validators for all visible fields.
  Future<bool> validateAsync({bool notify = true}) async {
    _ensureNotDisposed();
    if (!validate(notify: false)) {
      if (notify) _notify();
      return false;
    }

    final schema = _schema;
    if (schema == null) return true;

    _isValidating = true;
    if (notify) _notify();

    try {
      for (final field in schema.leafFields) {
        if (!isFieldVisible(field)) continue;
        final error = await _validateAsyncRules(field, _values[field.key]);
        if (error != null) {
          _errors[field.key] = error;
        }
      }

      final ok = _errors.isEmpty;
      if (ok) {
        onValidationSuccess?.call(values);
      } else {
        onValidationFailed?.call(errors);
      }
      return ok;
    } finally {
      _isValidating = false;
      if (notify) _notify();
    }
  }

  /// Validates (including async) and invokes submit callbacks on success.
  Future<bool> submit({bool nestGroups = false}) async {
    _ensureNotDisposed();
    _isSubmitting = true;
    _notify();

    try {
      final ok = await validateAsync();
      if (!ok) return false;

      final snapshot = nestGroups ? nestedValues : values;
      onSaved?.call(snapshot);
      onSubmit?.call(snapshot);
      return true;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// Resets values to schema defaults and clears errors / dirty flag.
  void reset() {
    _ensureNotDisposed();
    final schema = _schema;
    _values.clear();
    _errors.clear();
    _isDirty = false;
    _isSubmitting = false;
    _isValidating = false;
    if (schema != null) {
      _seedDefaults(schema.fields);
    }
    onChanged?.call(values);
    _notify();
  }

  /// Clears all leaf values and errors.
  void clear() {
    _ensureNotDisposed();
    final schema = _schema;
    if (schema != null) {
      for (final field in schema.leafFields) {
        _values[field.key] = _defaultFor(field);
      }
    } else {
      for (final key in _values.keys.toList()) {
        _values[key] = null;
      }
    }
    _errors.clear();
    _isDirty = true;
    onChanged?.call(values);
    _notify();
  }

  /// Registers or replaces a named sync custom validator.
  void registerValidator(String name, FieldValidator validator) {
    _customValidators[name] = validator;
  }

  /// Registers or replaces a named async validator.
  void registerAsyncValidator(String name, AsyncFieldValidator validator) {
    _asyncValidators[name] = validator;
  }

  /// Sets the global server validator used by `type: server` rules.
  void setServerValidator(ServerFieldValidator? validator) {
    _serverValidator = validator;
  }

  /// Error message for [key], if any.
  String? errorFor(String key) => _errors[key];

  /// Field schema for [key], if bound.
  FormFieldSchema? fieldFor(String key) => _schema?.fieldByKey(key);

  String? _validateSync(FormFieldSchema field, dynamic value) {
    final syncError = Validators.validateField(
      field: field,
      value: value,
      values: _values,
      customValidators: _customValidators,
    );
    if (syncError != null) return syncError;

    if (field.isRepeatable) {
      final list = value is List ? value : const <dynamic>[];
      if (field.minItems != null && list.length < field.minItems!) {
        return '${field.effectiveLabel} requires at least ${field.minItems} items';
      }
      if (field.maxItems != null && list.length > field.maxItems!) {
        return '${field.effectiveLabel} allows at most ${field.maxItems} items';
      }
    }
    return null;
  }

  Future<String?> _validateAsyncRules(
    FormFieldSchema field,
    dynamic value,
  ) async {
    for (final rule in field.validators) {
      if (rule.type != ValidatorType.async &&
          rule.type != ValidatorType.server) {
        continue;
      }

      final context = ValidationContext(
        field: field,
        values: _values,
        rule: rule,
      );

      if (rule.type == ValidatorType.async) {
        final name = rule.name ?? rule.pattern ?? rule.params['name'] as String?;
        if (name == null) continue;
        final validator = _asyncValidators[name];
        if (validator == null) continue;
        final error = await validator(value, context);
        if (error != null) return error;
      }

      if (rule.type == ValidatorType.server) {
        final validator = _serverValidator;
        if (validator == null) continue;
        final error = await validator(value, context, rule);
        if (error != null) return error;
      }
    }
    return null;
  }

  void _seedDefaults(List<FormFieldSchema> fields) {
    for (final field in fields) {
      if (field.isGroup) {
        _seedDefaults(field.fields);
      } else {
        _values[field.key] = field.defaultValue ?? _defaultFor(field);
      }
    }
  }

  dynamic _defaultFor(FormFieldSchema field) {
    switch (field.type) {
      case FieldType.checkbox:
      case FieldType.switchField:
        return false;
      case FieldType.chips:
      case FieldType.repeatable:
      case FieldType.signature:
        return <dynamic>[];
      case FieldType.slider:
        return field.min ?? 0;
      case FieldType.rangeSlider:
        return <num>[field.min ?? 0, field.max ?? 1];
      case FieldType.rating:
        return 0;
      case FieldType.color:
        return '#2196F3';
      case FieldType.image:
      case FieldType.file:
      case FieldType.camera:
      case FieldType.location:
      case FieldType.text:
      case FieldType.email:
      case FieldType.password:
      case FieldType.number:
      case FieldType.phone:
      case FieldType.multiline:
      case FieldType.radio:
      case FieldType.dropdown:
      case FieldType.date:
      case FieldType.time:
      case FieldType.dateTime:
      case FieldType.group:
      case FieldType.custom:
      case FieldType.unknown:
        return null;
    }
  }

  Map<String, dynamic> _buildNested(List<FormFieldSchema> fields) {
    final result = <String, dynamic>{};
    for (final field in fields) {
      if (!isFieldVisible(field) && !field.isGroup) continue;
      if (field.isGroup) {
        if (!isFieldVisible(field)) continue;
        result[field.key] = _buildNested(field.fields);
      } else {
        result[field.key] = _serializeValue(_values[field.key]);
      }
    }
    return result;
  }

  dynamic _serializeValue(dynamic value) {
    if (value is MediaFileValue) return value.toJson();
    if (value is LocationValue) return value.toJson();
    if (value is List) {
      return value.map(_serializeValue).toList();
    }
    return value;
  }

  void _pruneHiddenErrors() {
    final schema = _schema;
    if (schema == null) return;
    for (final field in schema.leafFields) {
      if (!isFieldVisible(field)) {
        _errors.remove(field.key);
      }
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _ensureNotDisposed() {
    assert(!_disposed, 'DynamicFormController was used after being disposed.');
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
