import 'package:flutter/widgets.dart';

/// Localizable copy for form chrome and built-in validation messages.
@immutable
class DynamicFormLocalizations {
  /// Creates [DynamicFormLocalizations].
  const DynamicFormLocalizations({
    this.submitLabel = 'Submit',
    this.resetLabel = 'Reset',
    this.requiredMessage = '{label} is required',
    this.emailMessage = 'Enter a valid email address',
    this.phoneMessage = 'Enter a valid phone number',
    this.invalidMessage = '{label} is invalid',
    this.minMessage = '{label} must be at least {min}',
    this.maxMessage = '{label} must be at most {max}',
    this.lengthMinMessage = '{label} must be at least {min} characters',
    this.lengthMaxMessage = '{label} must be at most {max} characters',
    this.compareMessage = '{label} must match {field}',
    this.addItemLabel = 'Add item',
    this.removeItemLabel = 'Remove',
    this.pickImageLabel = 'Pick image',
    this.takePhotoLabel = 'Take photo',
    this.pickFileLabel = 'Pick file',
    this.getLocationLabel = 'Get location',
    this.clearLabel = 'Clear',
    this.mediaNotConfigured =
        'Media service not configured. Register FormMediaServices via plugins.',
    this.loadingLabel = 'Loading…',
    this.itemLabel = 'Item {index}',
  });

  /// Default submit button label.
  final String submitLabel;

  /// Default reset button label.
  final String resetLabel;

  /// Required field message template (`{label}`).
  final String requiredMessage;

  /// Invalid email message.
  final String emailMessage;

  /// Invalid phone message.
  final String phoneMessage;

  /// Generic invalid message (`{label}`).
  final String invalidMessage;

  /// Numeric min message (`{label}`, `{min}`).
  final String minMessage;

  /// Numeric max message (`{label}`, `{max}`).
  final String maxMessage;

  /// Length min message.
  final String lengthMinMessage;

  /// Length max message.
  final String lengthMaxMessage;

  /// Compare mismatch message (`{label}`, `{field}`).
  final String compareMessage;

  /// Repeatable add button.
  final String addItemLabel;

  /// Repeatable remove button.
  final String removeItemLabel;

  /// Image picker button.
  final String pickImageLabel;

  /// Camera button.
  final String takePhotoLabel;

  /// File picker button.
  final String pickFileLabel;

  /// Location button.
  final String getLocationLabel;

  /// Clear action.
  final String clearLabel;

  /// Shown when media services are missing.
  final String mediaNotConfigured;

  /// Generic loading label.
  final String loadingLabel;

  /// Repeatable item title (`{index}`).
  final String itemLabel;

  /// Formats a template replacing `{key}` placeholders.
  String format(String template, Map<String, String> params) {
    var result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  /// Returns nearest localizations or English defaults.
  static DynamicFormLocalizations of(BuildContext context) =>
      DynamicFormLocalizationsProvider.of(context);

  /// English defaults.
  static const DynamicFormLocalizations en = DynamicFormLocalizations();

  /// Creates a copy with overrides.
  DynamicFormLocalizations copyWith({
    String? submitLabel,
    String? resetLabel,
    String? requiredMessage,
    String? emailMessage,
    String? phoneMessage,
    String? invalidMessage,
    String? minMessage,
    String? maxMessage,
    String? lengthMinMessage,
    String? lengthMaxMessage,
    String? compareMessage,
    String? addItemLabel,
    String? removeItemLabel,
    String? pickImageLabel,
    String? takePhotoLabel,
    String? pickFileLabel,
    String? getLocationLabel,
    String? clearLabel,
    String? mediaNotConfigured,
    String? loadingLabel,
    String? itemLabel,
  }) {
    return DynamicFormLocalizations(
      submitLabel: submitLabel ?? this.submitLabel,
      resetLabel: resetLabel ?? this.resetLabel,
      requiredMessage: requiredMessage ?? this.requiredMessage,
      emailMessage: emailMessage ?? this.emailMessage,
      phoneMessage: phoneMessage ?? this.phoneMessage,
      invalidMessage: invalidMessage ?? this.invalidMessage,
      minMessage: minMessage ?? this.minMessage,
      maxMessage: maxMessage ?? this.maxMessage,
      lengthMinMessage: lengthMinMessage ?? this.lengthMinMessage,
      lengthMaxMessage: lengthMaxMessage ?? this.lengthMaxMessage,
      compareMessage: compareMessage ?? this.compareMessage,
      addItemLabel: addItemLabel ?? this.addItemLabel,
      removeItemLabel: removeItemLabel ?? this.removeItemLabel,
      pickImageLabel: pickImageLabel ?? this.pickImageLabel,
      takePhotoLabel: takePhotoLabel ?? this.takePhotoLabel,
      pickFileLabel: pickFileLabel ?? this.pickFileLabel,
      getLocationLabel: getLocationLabel ?? this.getLocationLabel,
      clearLabel: clearLabel ?? this.clearLabel,
      mediaNotConfigured: mediaNotConfigured ?? this.mediaNotConfigured,
      loadingLabel: loadingLabel ?? this.loadingLabel,
      itemLabel: itemLabel ?? this.itemLabel,
    );
  }
}

/// Inherited localizations for form widgets.
class DynamicFormLocalizationsProvider extends InheritedWidget {
  /// Creates a provider.
  const DynamicFormLocalizationsProvider({
    super.key,
    required this.localizations,
    required super.child,
  });

  /// Active localizations.
  final DynamicFormLocalizations localizations;

  /// Returns nearest localizations or English defaults.
  static DynamicFormLocalizations of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<DynamicFormLocalizationsProvider>();
    return provider?.localizations ?? DynamicFormLocalizations.en;
  }

  @override
  bool updateShouldNotify(DynamicFormLocalizationsProvider oldWidget) =>
      localizations != oldWidget.localizations;
}
