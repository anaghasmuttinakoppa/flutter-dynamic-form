import 'package:flutter/widgets.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/form_field_schema.dart';
import '../models/media_value.dart';
import '../theme/dynamic_form_theme.dart';

/// Context passed to custom field renderers.
@immutable
class FieldRenderContext {
  /// Creates a [FieldRenderContext].
  const FieldRenderContext({
    required this.context,
    required this.field,
    required this.controller,
    required this.theme,
  });

  /// Build context.
  final BuildContext context;

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Resolved theme.
  final DynamicFormTheme theme;
}

/// Builds a widget for a field schema.
typedef FieldRenderer = Widget Function(FieldRenderContext ctx);

/// Picks images from gallery.
abstract class FormImagePicker {
  /// Picks a single image from the gallery.
  Future<MediaFileValue?> pickFromGallery();
}

/// Captures images from the camera.
abstract class FormCameraCapture {
  /// Captures a photo with the device camera.
  Future<MediaFileValue?> capture();
}

/// Picks arbitrary files.
abstract class FormFilePicker {
  /// Picks one or more files.
  ///
  /// When [allowMultiple] is false, at most one file is returned.
  Future<List<MediaFileValue>> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  });
}

/// Provides the device's current location.
abstract class FormLocationProvider {
  /// Returns the current location, or `null` if unavailable / denied.
  Future<LocationValue?> getCurrentLocation();
}

/// Bundles injectable media services for Phase 4 fields.
@immutable
class FormMediaServices {
  /// Creates [FormMediaServices].
  const FormMediaServices({
    this.imagePicker,
    this.camera,
    this.filePicker,
    this.location,
  });

  /// Gallery image picker.
  final FormImagePicker? imagePicker;

  /// Camera capture.
  final FormCameraCapture? camera;

  /// File picker.
  final FormFilePicker? filePicker;

  /// Location provider.
  final FormLocationProvider? location;

  /// Empty services (media buttons show configuration hints).
  static const FormMediaServices none = FormMediaServices();

  /// Returns a copy with selected services replaced.
  FormMediaServices copyWith({
    FormImagePicker? imagePicker,
    FormCameraCapture? camera,
    FormFilePicker? filePicker,
    FormLocationProvider? location,
  }) {
    return FormMediaServices(
      imagePicker: imagePicker ?? this.imagePicker,
      camera: camera ?? this.camera,
      filePicker: filePicker ?? this.filePicker,
      location: location ?? this.location,
    );
  }
}

/// Registry for custom field renderers and media services (Phase 5 plugin API).
class DynamicFormPluginRegistry {
  /// Creates a registry.
  DynamicFormPluginRegistry({
    FormMediaServices mediaServices = FormMediaServices.none,
  }) : _mediaServices = mediaServices;

  final Map<String, FieldRenderer> _byTypeName = <String, FieldRenderer>{};
  FormMediaServices _mediaServices;

  /// Active media services.
  FormMediaServices get mediaServices => _mediaServices;

  /// Replaces media service implementations.
  void setMediaServices(FormMediaServices services) {
    _mediaServices = services;
  }

  /// Registers a renderer for a JSON `type` string (e.g. `otp`, `custom_map`).
  void registerRenderer(String typeName, FieldRenderer renderer) {
    _byTypeName[typeName.toLowerCase().trim()] = renderer;
  }

  /// Removes a previously registered renderer.
  void unregisterRenderer(String typeName) {
    _byTypeName.remove(typeName.toLowerCase().trim());
  }

  /// Looks up a renderer by type name.
  FieldRenderer? rendererFor(String typeName) =>
      _byTypeName[typeName.toLowerCase().trim()];

  /// Whether a custom renderer exists for [typeName].
  bool hasRenderer(String typeName) =>
      _byTypeName.containsKey(typeName.toLowerCase().trim());

  /// Clears all custom renderers (media services kept).
  void clearRenderers() => _byTypeName.clear();
}

/// Inherited access to the plugin registry.
class DynamicFormPlugins extends InheritedWidget {
  /// Creates [DynamicFormPlugins].
  const DynamicFormPlugins({
    super.key,
    required this.registry,
    required super.child,
  });

  /// Plugin registry.
  final DynamicFormPluginRegistry registry;

  /// Returns the nearest registry, or creates an empty ephemeral one.
  static DynamicFormPluginRegistry of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<DynamicFormPlugins>();
    return inherited?.registry ?? DynamicFormPluginRegistry();
  }

  /// Returns the registry without registering a dependency.
  static DynamicFormPluginRegistry? maybeOf(BuildContext context) {
    final inherited =
        context.getInheritedWidgetOfExactType<DynamicFormPlugins>();
    return inherited?.registry;
  }

  @override
  bool updateShouldNotify(DynamicFormPlugins oldWidget) =>
      registry != oldWidget.registry;
}
