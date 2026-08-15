import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../core/enums.dart';
import '../../l10n/dynamic_form_localizations.dart';
import '../../models/form_field_schema.dart';
import '../../models/media_value.dart';
import '../../plugins/plugin_registry.dart';
import '../../theme/dynamic_form_theme.dart';

/// Image / camera / file picker field.
class DynamicMediaField extends StatefulWidget {
  /// Creates a [DynamicMediaField].
  const DynamicMediaField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  @override
  State<DynamicMediaField> createState() => _DynamicMediaFieldState();
}

class _DynamicMediaFieldState extends State<DynamicMediaField> {
  bool _busy = false;

  FormFieldSchema get field => widget.field;
  DynamicFormController get formController => widget.controller;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? DynamicFormThemeProvider.of(context);
    final l10n = DynamicFormLocalizations.of(context);
    final enabled = formController.isFieldEnabled(field);
    final error = formController.errorFor(field.key);
    final value = formController.getValue(field.key);
    final material = Theme.of(context);

    final summary = _summary(value);

    return Semantics(
      label: field.effectiveSemanticLabel,
      button: true,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            field.effectiveLabel,
            style: theme.labelStyle ?? material.textTheme.titleSmall,
          ),
          if (field.helperText != null && error == null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(field.helperText!, style: theme.helperStyle),
            ),
          const SizedBox(height: 8),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(summary, style: material.textTheme.bodyMedium),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: !enabled || _busy ? null : () => _pick(context),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_iconFor(field.type)),
                label: Text(_label(l10n)),
              ),
              if (summary != null)
                OutlinedButton(
                  onPressed: !enabled || _busy
                      ? null
                      : () => formController.updateField(field.key, null),
                  child: Text(l10n.clearLabel),
                ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: theme.errorStyle ??
                    TextStyle(color: material.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(FieldType type) {
    switch (type) {
      case FieldType.camera:
        return Icons.photo_camera_outlined;
      case FieldType.file:
        return Icons.attach_file;
      case FieldType.image:
      default:
        return Icons.image_outlined;
    }
  }

  String _label(DynamicFormLocalizations l10n) {
    switch (field.type) {
      case FieldType.camera:
        return l10n.takePhotoLabel;
      case FieldType.file:
        return l10n.pickFileLabel;
      case FieldType.image:
      default:
        return l10n.pickImageLabel;
    }
  }

  String? _summary(dynamic value) {
    if (value == null) return null;
    if (value is MediaFileValue) {
      return value.name ?? value.path ?? 'Selected file';
    }
    if (value is List && value.isNotEmpty) {
      return value
          .map((e) => e is MediaFileValue ? (e.name ?? e.path) : e.toString())
          .whereType<String>()
          .join(', ');
    }
    if (value is Map) {
      return value['name']?.toString() ?? value['path']?.toString();
    }
    return value.toString();
  }

  Future<void> _pick(BuildContext context) async {
    final registry = DynamicFormPlugins.of(context);
    final l10n = DynamicFormLocalizations.of(context);
    final services = registry.mediaServices;

    setState(() => _busy = true);
    try {
      switch (field.type) {
        case FieldType.camera:
          final camera = services.camera;
          if (camera == null) {
            _showMissing(context, l10n);
            return;
          }
          final shot = await camera.capture();
          if (shot != null) {
            formController.updateField(field.key, shot);
          }
        case FieldType.file:
          final picker = services.filePicker;
          if (picker == null) {
            _showMissing(context, l10n);
            return;
          }
          final files = await picker.pickFiles(
            allowMultiple: field.allowMultiple,
            allowedExtensions: field.allowedExtensions.isEmpty
                ? null
                : field.allowedExtensions,
          );
          if (files.isEmpty) return;
          formController.updateField(
            field.key,
            field.allowMultiple ? files : files.first,
          );
        case FieldType.image:
        default:
          final picker = services.imagePicker;
          if (picker == null) {
            _showMissing(context, l10n);
            return;
          }
          final image = await picker.pickFromGallery();
          if (image != null) {
            formController.updateField(field.key, image);
          }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMissing(BuildContext context, DynamicFormLocalizations l10n) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.mediaNotConfigured)),
    );
  }
}

/// Location field using [FormLocationProvider].
class DynamicLocationField extends StatefulWidget {
  /// Creates a [DynamicLocationField].
  const DynamicLocationField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  @override
  State<DynamicLocationField> createState() => _DynamicLocationFieldState();
}

class _DynamicLocationFieldState extends State<DynamicLocationField> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? DynamicFormThemeProvider.of(context);
    final l10n = DynamicFormLocalizations.of(context);
    final field = widget.field;
    final formController = widget.controller;
    final enabled = formController.isFieldEnabled(field);
    final error = formController.errorFor(field.key);
    final value = formController.getValue(field.key);
    final material = Theme.of(context);

    String? summary;
    if (value is LocationValue) {
      summary = value.address ??
          '${value.latitude.toStringAsFixed(5)}, '
              '${value.longitude.toStringAsFixed(5)}';
    } else if (value is Map) {
      summary =
          '${value['latitude']}, ${value['longitude']}';
    }

    return Semantics(
      label: field.effectiveSemanticLabel,
      button: true,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            field.effectiveLabel,
            style: theme.labelStyle ?? material.textTheme.titleSmall,
          ),
          if (field.helperText != null && error == null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(field.helperText!, style: theme.helperStyle),
            ),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(summary),
            ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: !enabled || _busy
                    ? null
                    : () => _locate(context),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(l10n.getLocationLabel),
              ),
              if (summary != null)
                OutlinedButton(
                  onPressed: !enabled || _busy
                      ? null
                      : () => formController.updateField(field.key, null),
                  child: Text(l10n.clearLabel),
                ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: theme.errorStyle ??
                    TextStyle(color: material.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _locate(BuildContext context) async {
    final l10n = DynamicFormLocalizations.of(context);
    final provider = DynamicFormPlugins.of(context).mediaServices.location;
    if (provider == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.mediaNotConfigured)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final location = await provider.getCurrentLocation();
      if (location != null) {
        widget.controller.updateField(widget.field.key, location);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
