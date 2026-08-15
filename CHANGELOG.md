# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-15

### Changed
- Published package name is **`json_driven_dynamic_form`**. pub.dev rejected `flutter_dynamic_form` (too similar to `flutter_dynamic_forms`) and `json_dynamic_form` was already taken.

### Added

#### Publish readiness
- Pre-render **schema JSON validation** (`FormSchemaValidator`) with path-aware issues
- `SchemaErrorView` UI when schema is invalid (shows JSON paths instead of the form)
- `DynamicForm.validateSchema` / `onSchemaInvalid` callbacks
- Responsive layout: `SafeArea`, keyboard insets, stacked actions on narrow widths, `maxContentWidth`

#### Phase 4
- Media field types: `image`, `file`, `camera`, `location`
- Injectable media services (`FormImagePicker`, `FormCameraCapture`, `FormFilePicker`, `FormLocationProvider`)
- `MediaFileValue` / `LocationValue` models
- Mock media services for tests and demos (`mockMediaServices()`)
- Async validators (`type: async`) via `registerAsyncValidator`
- Server validators (`type: server`) via `setServerValidator`
- `validateAsync()` and async-aware `submit()`
- Example: Media Upload demo

#### Phase 5
- Plugin API: `DynamicFormPluginRegistry` + custom `FieldRenderer`s
- Field types: `slider`, `rangeSlider`, `rating`, `signature`, `color`, `custom`, `repeatable`
- Repeatable sections with add/remove/min/max items
- Localization: `DynamicFormLocalizations`
- Accessibility: `Semantics` wrappers + `semanticLabel`
- Example: Advanced Controls demo (custom badge renderer)

### Changed
- Package version `0.3.0` → `1.0.0` (Phases 1–5 complete)

## [0.3.0] - 2026-07-23

### Added

#### Phase 2
- Field types: `checkbox`, `switch`, `radio`, `dropdown`, `chips`, `date`, `time`, `datetime`
- Conditional visibility / enabled via `visibleWhen` and `enabledWhen`
- Animated field show/hide

#### Phase 3
- Nested `group` fields
- `compare` validator
- `nestedValues` API
- Theme group/animation polish

## [0.1.0] - 2026-07-23

### Added

- Phase 1 text fields, validation, controller, example, docs

[1.0.0]: https://github.com/anaghasmuttinakoppa/flutter-dynamic-form/releases/tag/v1.0.0
[0.3.0]: https://github.com/anaghasmuttinakoppa/flutter-dynamic-form/releases/tag/v0.3.0
[0.1.0]: https://github.com/anaghasmuttinakoppa/flutter-dynamic-form/releases/tag/v0.1.0
