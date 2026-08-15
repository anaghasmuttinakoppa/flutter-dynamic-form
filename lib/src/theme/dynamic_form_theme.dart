import 'package:flutter/material.dart';

/// Theme customization for [DynamicForm] and its fields.
@immutable
class DynamicFormTheme {
  /// Creates a [DynamicFormTheme].
  const DynamicFormTheme({
    this.fieldSpacing = 16,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    this.borderRadius = 8,
    this.titleStyle,
    this.descriptionStyle,
    this.labelStyle,
    this.errorStyle,
    this.helperStyle,
    this.groupTitleStyle,
    this.inputDecorationTheme,
    this.submitButtonStyle,
    this.resetButtonStyle,
    this.showResetButton = true,
    this.dense = false,
    this.animateFields = true,
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeInOut,
    this.groupDecoration = true,
    this.groupPadding = const EdgeInsets.all(16),
    this.groupBackgroundColor,
    this.groupBorderColor,
    this.maxContentWidth = 720,
  });

  /// Vertical spacing between fields.
  final double fieldSpacing;

  /// Default content padding for text fields.
  final EdgeInsetsGeometry contentPadding;

  /// Corner radius for outlined inputs.
  final double borderRadius;

  /// Style for the form title.
  final TextStyle? titleStyle;

  /// Style for the form description.
  final TextStyle? descriptionStyle;

  /// Style for field labels.
  final TextStyle? labelStyle;

  /// Style for error text.
  final TextStyle? errorStyle;

  /// Style for helper text.
  final TextStyle? helperStyle;

  /// Style for nested group titles.
  final TextStyle? groupTitleStyle;

  /// Optional Material input decoration theme override.
  final InputDecorationTheme? inputDecorationTheme;

  /// Style for the submit button.
  final ButtonStyle? submitButtonStyle;

  /// Style for the reset button.
  final ButtonStyle? resetButtonStyle;

  /// Whether to show the reset button.
  final bool showResetButton;

  /// Whether fields should use dense layout.
  final bool dense;

  /// Whether to animate field show/hide (conditions).
  final bool animateFields;

  /// Duration for field enter/exit animations.
  final Duration animationDuration;

  /// Curve for field enter/exit animations.
  final Curve animationCurve;

  /// Whether nested groups render inside a bordered container.
  final bool groupDecoration;

  /// Padding inside nested group containers.
  final EdgeInsetsGeometry groupPadding;

  /// Background for nested groups.
  final Color? groupBackgroundColor;

  /// Border color for nested groups.
  final Color? groupBorderColor;

  /// Max form width on large screens (tablets / desktop). `null` = full width.
  final double? maxContentWidth;

  /// Creates a copy with selected properties replaced.
  DynamicFormTheme copyWith({
    double? fieldSpacing,
    EdgeInsetsGeometry? contentPadding,
    double? borderRadius,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    TextStyle? labelStyle,
    TextStyle? errorStyle,
    TextStyle? helperStyle,
    TextStyle? groupTitleStyle,
    InputDecorationTheme? inputDecorationTheme,
    ButtonStyle? submitButtonStyle,
    ButtonStyle? resetButtonStyle,
    bool? showResetButton,
    bool? dense,
    bool? animateFields,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? groupDecoration,
    EdgeInsetsGeometry? groupPadding,
    Color? groupBackgroundColor,
    Color? groupBorderColor,
    double? maxContentWidth,
  }) {
    return DynamicFormTheme(
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      contentPadding: contentPadding ?? this.contentPadding,
      borderRadius: borderRadius ?? this.borderRadius,
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      helperStyle: helperStyle ?? this.helperStyle,
      groupTitleStyle: groupTitleStyle ?? this.groupTitleStyle,
      inputDecorationTheme:
          inputDecorationTheme ?? this.inputDecorationTheme,
      submitButtonStyle: submitButtonStyle ?? this.submitButtonStyle,
      resetButtonStyle: resetButtonStyle ?? this.resetButtonStyle,
      showResetButton: showResetButton ?? this.showResetButton,
      dense: dense ?? this.dense,
      animateFields: animateFields ?? this.animateFields,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      groupDecoration: groupDecoration ?? this.groupDecoration,
      groupPadding: groupPadding ?? this.groupPadding,
      groupBackgroundColor:
          groupBackgroundColor ?? this.groupBackgroundColor,
      groupBorderColor: groupBorderColor ?? this.groupBorderColor,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    );
  }

  /// Resolves a theme, falling back to defaults.
  static DynamicFormTheme resolve(
    BuildContext context, [
    DynamicFormTheme? theme,
  ]) {
    return theme ?? const DynamicFormTheme();
  }
}

/// Inherited theme for descendant form widgets.
class DynamicFormThemeProvider extends InheritedWidget {
  /// Creates a [DynamicFormThemeProvider].
  const DynamicFormThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  /// The theme to expose.
  final DynamicFormTheme theme;

  /// Returns the nearest [DynamicFormTheme], or defaults.
  static DynamicFormTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<DynamicFormThemeProvider>();
    return provider?.theme ?? const DynamicFormTheme();
  }

  @override
  bool updateShouldNotify(DynamicFormThemeProvider oldWidget) =>
      theme != oldWidget.theme;
}
