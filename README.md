# flutter_dynamic_form

Generate fully dynamic, validated Flutter forms from JSON — no manual widget wiring.

[![pub package](https://img.shields.io/pub/v/flutter_dynamic_form.svg)](https://pub.dev/packages/flutter_dynamic_form)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> **Version:** 1.0.0 · **SDK:** Dart `^3.5.0` · Flutter `>=3.24.0`  
> **Dependencies:** Flutter SDK only (no hard deps on `image_picker`, `geolocator`, etc.)

This document is the end-to-end reference for the package: schema format, every field type, validators, conditions, controller API, plugins, theming, localization, values shape, and common pitfalls — so you should not need to reverse-engineer the source later.

---

## Table of contents

1. [What this package solves](#what-this-package-solves)
2. [Installation](#installation)
3. [Quick start](#quick-start)
4. [How it works](#how-it-works)
5. [Schema JSON reference](#schema-json-reference)
6. [Field types](#field-types)
7. [Validators](#validators)
8. [Conditional visibility & enabled](#conditional-visibility--enabled)
9. [Nested groups & repeatable sections](#nested-groups--repeatable-sections)
10. [Schema validation (pre-render)](#schema-validation-pre-render)
11. [DynamicForm widget API](#dynamicform-widget-api)
12. [DynamicFormController API](#dynamicformcontroller-api)
13. [Submitted values shape](#submitted-values-shape)
14. [Media fields & injectable services](#media-fields--injectable-services)
15. [Custom field renderers (plugins)](#custom-field-renderers-plugins)
16. [Theming](#theming)
17. [Localization](#localization)
18. [Accessibility](#accessibility)
19. [Responsive / platform notes](#responsive--platform-notes)
20. [Example app](#example-app)
21. [Public API checklist](#public-api-checklist)
22. [Troubleshooting](#troubleshooting)
23. [Docs & license](#docs--license)

---

## What this package solves

You describe a form once as JSON (or a Dart `Map` / `FormSchema`). The package:

1. **Validates** the schema structure (paths like `fields[0].key`)
2. **Renders** Material fields for 25+ types
3. **Tracks** values, dirty state, sync/async errors
4. **Evaluates** `visibleWhen` / `enabledWhen`
5. **Submits** a plain `Map<String, dynamic>` you can send to an API

Use it when forms are configured by a backend, CMS, or product team without shipping a new app build for every layout change.

**Not included by design:** native pickers. Media types use injectable interfaces so the package stays dependency-light and pub-friendly. Wire `image_picker` / `file_picker` / `geolocator` (or mocks) in your app.

---

## Installation

```yaml
dependencies:
  flutter_dynamic_form: ^1.0.0
```

```dart
import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
```

---

## Quick start

```dart
final controller = DynamicFormController();

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: DynamicForm(
      json: {
        'title': 'User Registration',
        'description': 'Create your account',
        'submitLabel': 'Continue',
        'fields': [
          {
            'type': 'text',
            'key': 'name',
            'label': 'Full Name',
            'required': true,
            'validators': [
              {'type': 'length', 'min': 2, 'max': 80},
            ],
          },
          {'type': 'email', 'key': 'email', 'required': true},
          {
            'type': 'password',
            'key': 'password',
            'label': 'Password',
            'required': true,
            'validators': [
              {'type': 'length', 'min': 8},
            ],
          },
          {
            'type': 'password',
            'key': 'confirmPassword',
            'label': 'Confirm password',
            'required': true,
            'validators': [
              {
                'type': 'compare',
                'field': 'password',
                'operator': 'equals',
                'message': 'Passwords must match',
              },
            ],
          },
        ],
      },
      controller: controller,
      onSubmit: (values) {
        // values == { name, email, password, confirmPassword }
        debugPrint('$values');
      },
      onSchemaInvalid: (result) {
        // Prefer fixing JSON; SchemaErrorView is already shown in the UI.
        debugPrint(result.errors.join('\n'));
      },
    ),
  );
}
```

`json` accepts:

| Input | Behavior |
| --- | --- |
| `Map<String, dynamic>` / `Map` | Validated then parsed |
| JSON `String` | Decoded, validated, parsed |
| `FormSchema` | Bound directly (skips JSON structure validation) |

---

## How it works

```text
JSON / Map
   │
   ▼
FormSchemaValidator  ──fail──►  SchemaErrorView (paths + messages)
   │ pass
   ▼
FormSchemaParser  ──►  FormSchema + FormFieldSchema tree
   │
   ▼
DynamicFormController.bind()
   │
   ▼
FieldBuilder  ──►  Material widgets (or custom FieldRenderer)
   │
   ▼
validate / validateAsync / submit  ──►  Map values (+ optional nested groups)
```

- **Sync validators** run on change / `validate()` / before async on submit.
- **Async / server** validators run via `validateAsync()` and inside `submit()`.
- **Conditions** re-evaluate when values change; fields animate show/hide when themed.

---

## Schema JSON reference

### Root (`FormSchema`)

| Property | Aliases | Type | Default | Notes |
| --- | --- | --- | --- | --- |
| `title` | — | `string?` | `null` | Form heading |
| `description` | — | `string?` | `null` | Subtitle |
| `submitLabel` | `submit_label` | `string` | `"Submit"` | Overridable by widget |
| `resetLabel` | `reset_label` | `string` | `"Reset"` | Overridable by widget |
| `fields` | `items` | `array` | **required** | At least one field recommended |
| *(other keys)* | — | any | — | Stored in `schema.extra` |

Minimal valid document:

```json
{
  "fields": [
    { "type": "text", "key": "name" }
  ]
}
```

### Field object (`FormFieldSchema`) — common keys

| Property | Aliases | Type | Notes |
| --- | --- | --- | --- |
| `key` | `name` | `string` | **Required.** Unique among siblings / root (except repeatable template children) |
| `type` | — | `string` | Field type or alias (see below) |
| `label` | — | `string?` | Shown as field label |
| `hint` | — | `string?` | Hint / decoration |
| `helperText` | `helper_text` | `string?` | Helper under field |
| `placeholder` | — | `string?` | Placeholder text |
| `defaultValue` | `default`, `value` | any | Initial value |
| `required` | — | `bool` | Injects a `required` validator |
| `enabled` | — | `bool` | Base enabled flag |
| `visible` | — | `bool` | Base visibility |
| `readOnly` | `read_only` | `bool` | Forces disabled editing |
| `validators` | — | `array` | Strings and/or rule objects |
| `visibleWhen` | `visible_when`, `showWhen`, `show_when`, `condition` | object/list | Conditional visibility |
| `enabledWhen` | `enabled_when`, `enableWhen`, `enable_when` | object/list | Conditional enable |
| `semanticLabel` | `semantic_label` | `string?` | Accessibility label |
| `options` | `items`, `choices` | `array` | radio / dropdown / chips / color swatches |
| `fields` | `children`, `items` | `array` | Nested for `group` / `repeatable` |
| *(unknown keys)* | — | any | Stored in `field.extra` |

Type-specific keys are listed under [Field types](#field-types).

### Options

Accepted shapes for each option entry:

```json
"US"
```

```json
{ "value": "US", "label": "United States", "enabled": true }
```

Also accepts `text` / `title` as label aliases. Numbers and booleans are allowed as bare values.

---

## Field types

Aliases are case-insensitive after trim. Prefer the **canonical** name in new schemas.

### Text & numbers

| Canonical | Aliases | Notes / extra keys |
| --- | --- | --- |
| `text` | `string` | `keyboardType`, `prefixIcon`, `suffixIcon`, `maxLines`, `regex` / `pattern` |
| `email` | — | Auto email validator; email keyboard |
| `password` | — | Obscured; `obscureText` / `obscure_text` |
| `number` | `int`, `integer`, `double`, `numeric` | `min`/`minimum`, `max`/`maximum` → auto min/max validators |
| `phone` | `tel`, `telephone` | Auto phone validator |
| `multiline` | `textarea`, `text_area` | `minLines`/`min_lines`, `maxLines`/`max_lines` (defaults ~3 / 4) |

```json
{
  "type": "number",
  "key": "age",
  "label": "Age",
  "min": 18,
  "max": 120,
  "required": true
}
```

### Boolean

| Canonical | Aliases | Notes |
| --- | --- | --- |
| `checkbox` | `check`, `bool`, `boolean` | Default `false`; required ⇒ must be `true` |
| `switch` | `toggle` | Same semantics as checkbox |

### Selection

| Canonical | Aliases | Notes |
| --- | --- | --- |
| `radio` | `radiogroup`, `radio_group` | Single value; needs `options` |
| `dropdown` | `select`, `selectbox` | Single value; needs `options` |
| `chips` | `chip`, `multiselect`, `multi_select` | Multi-select; default `[]` |

### Date & time

| Canonical | Aliases | Format key | Default format |
| --- | --- | --- | --- |
| `date` | `datepicker`, `date_picker` | `dateFormat` / `date_format` | `yyyy-MM-dd` |
| `time` | `timepicker`, `time_picker` | same | `HH:mm` |
| `datetime` | `date_time`, `datetimepicker`, `date_time_picker` | same | `yyyy-MM-dd HH:mm` |

Values are stored as formatted strings matching the field format.

### Structure

| Canonical | Aliases | Extra keys |
| --- | --- | --- |
| `group` | `section`, `nested`, `fieldset` | Nested `fields` / `children` / `items` |
| `repeatable` | `repeater`, `list`, `array` | Template `fields`; `minItems`/`min_items`, `maxItems`/`max_items` |

### Media (requires plugins)

| Canonical | Aliases | Extra keys |
| --- | --- | --- |
| `image` | `imagepicker`, `image_picker`, `photo` | `allowMultiple` / `allow_multiple` |
| `file` | `filepicker`, `file_picker`, `attachment` | `allowedExtensions` / `allowed_extensions` / `accept`, `allowMultiple` |
| `camera` | `capture` | Needs `FormCameraCapture` |
| `location` | `geo`, `geolocation`, `gps` | Needs `FormLocationProvider` |

Without configured media services, UI shows a localized “not configured” message.

### Advanced

| Canonical | Aliases | Extra keys / value |
| --- | --- | --- |
| `slider` | — | `min`, `max`, `divisions`; value = `num` |
| `range_slider` | `rangeslider`, `range` | value = `[start, end]` |
| `rating` | `stars` | `max` = star count (default 5); value = `num` |
| `signature` | `sign` | value = list of stroke point maps |
| `color` | `colorpicker`, `color_picker` | hex string; optional `options` as swatches |
| `custom` | — | `customType` / `custom_type` / `renderer` → plugin lookup |

Unknown type strings become `FieldType.unknown` (placeholder) and may surface as a **schema warning**.

---

## Validators

### Declaring rules

```json
"validators": [
  "required",
  { "type": "length", "min": 2, "max": 50, "message": "Name length invalid" },
  { "type": "regex", "pattern": "^[A-Za-z ]+$" },
  { "type": "compare", "field": "password", "operator": "equals" },
  { "type": "async", "name": "uniqueEmail" },
  { "type": "server", "url": "/api/validate-email" }
]
```

Auto-injected (you don’t need to repeat them):

- `required: true` → required rule  
- field-level `regex` / `pattern`  
- number `min` / `max`  
- `email` / `phone` field types  

### Built-in rule types

| `type` | Aliases | Parameters | Default message idea |
| --- | --- | --- | --- |
| `required` | — | `message?` | `{label} is required` (checkbox/switch must be `true`) |
| `email` | — | `message?` | Enter a valid email |
| `phone` | `tel` | `message?` | Enter a valid phone |
| `regex` | `pattern` | `pattern` / `regex`, `message?` | `{label} is invalid` |
| `length` | — | `min`/`minimum`, `max`/`maximum`, `message?` | min/max character counts |
| `min` | `minimum` | `min` / `value`, `message?` | numeric lower bound |
| `max` | `maximum` | `max` / `value`, `message?` | numeric upper bound |
| `compare` | `match`, `equals_field` | `field` / `otherField` / `other_field`, `operator` / `op`, optional literal `value`, `message?` | must match other field |
| `async` | — | `name` (also `params.name`), `message?` | From registered async validator |
| `server` | `remote`, `api` | `url` / `endpoint`, `params?`, `message?` | From `setServerValidator` |
| *(custom name)* | — | looked up via `registerValidator` | No-op if unregistered |

Shared optional keys on rule maps: `type`/`name`, `message`, `pattern`/`regex`, `min`/`minimum`, `max`/`maximum`, `value`, `field`, `operator`/`op`, `url`/`endpoint`, `params`.

### Async & server (app code)

```dart
controller.registerAsyncValidator('uniqueEmail', (value, ctx) async {
  final ok = await api.isEmailFree(value as String?);
  return ok ? null : 'Email already registered';
});

controller.setServerValidator((value, ctx, rule) async {
  return api.validateRemote(rule.url!, value); // return String? error
});

// Sync only — skips async/server rules
final okSync = controller.validate();

// Includes async + server
final ok = await controller.validateAsync();
final submitted = await controller.submit(); // validateAsync then onSubmit
```

**Important:** sync `validate()` intentionally skips `async` / `server` rules. Always use `validateAsync()` or `submit()` when those rules matter.

---

## Conditional visibility & enabled

### Keys

| Purpose | Accepted keys |
| --- | --- |
| Show/hide | `visibleWhen`, `visible_when`, `showWhen`, `show_when`, `condition` |
| Enable/disable | `enabledWhen`, `enabled_when`, `enableWhen`, `enable_when` |

Both schema flags (`visible` / `enabled`) and conditions must pass. `readOnly: true` forces disabled.

### Condition shapes

```json
{ "field": "hasPet", "operator": "equals", "value": true }
```

```json
{ "field": "age", "op": "gte", "value": 18 }
```

```json
{ "field": "age", "gte": 18 }
```

```json
{ "country": "IN" }
```

```json
{
  "all": [
    { "field": "role", "operator": "equals", "value": "other" },
    { "field": "age", "operator": "gte", "value": 18 }
  ]
}
```

```json
{
  "any": [
    { "field": "plan", "op": "equals", "value": "pro" },
    { "field": "plan", "op": "equals", "value": "enterprise" }
  ]
}
```

- `{ "all": [...] }` / `{ "and": [...] }` → all must match  
- `{ "any": [...] }` / `{ "or": [...] }` → any may match  
- Bare list → treated as AND  

Field key aliases: `field`, `when`, `key`, `dependsOn`, `depends_on`.

### Operators (`ConditionOperator`)

| Operator | JSON aliases |
| --- | --- |
| `equals` | `eq`, `==`, `equals`, `equal` (default) |
| `notEquals` | `neq`, `ne`, `!=`, `notequals`, `not_equals` |
| `greaterThan` | `gt`, `>`, `greaterthan`, `greater_than` |
| `greaterThanOrEqual` | `gte`, `>=`, … |
| `lessThan` | `lt`, `<`, … |
| `lessThanOrEqual` | `lte`, `<=`, … |
| `contains` | `contains`, `include`, `includes` |
| `isEmpty` | `empty`, `isempty`, `is_empty` |
| `isNotEmpty` | `notempty`, `isnotempty`, `is_not_empty` |
| `isIn` | `in`, `isin`, `is_in` (expected value = list) |

Hidden fields are not shown; their values remain in the controller until cleared/reset (design choice — strip them in your submit handler if the API requires it).

---

## Nested groups & repeatable sections

### Group

```json
{
  "type": "group",
  "key": "address",
  "label": "Address",
  "fields": [
    { "type": "text", "key": "line1", "label": "Line 1", "required": true },
    { "type": "text", "key": "city", "label": "City", "required": true }
  ]
}
```

- **Flat values** (`controller.values`): child keys live at the root (`line1`, `city`). Child keys must be unique across the form (including other groups).
- **Nested values** (`controller.nestedValues` or `submit(nestGroups: true)`): nested under the group key:

```json
{ "address": { "line1": "...", "city": "..." } }
```

### Repeatable

```json
{
  "type": "repeatable",
  "key": "references",
  "label": "References",
  "minItems": 1,
  "maxItems": 5,
  "fields": [
    { "type": "text", "key": "name", "label": "Name", "required": true },
    { "type": "email", "key": "email", "label": "Email", "required": true }
  ]
}
```

Value shape:

```json
{
  "references": [
    { "name": "Ada", "email": "ada@example.com" },
    { "name": "Grace", "email": "grace@example.com" }
  ]
}
```

Controller helpers:

```dart
controller.addRepeatableItem('references');
controller.removeRepeatableItem('references', 0);
controller.updateRepeatableItemField('references', 0, 'name', 'Ada');
```

---

## Schema validation (pre-render)

By default (`validateSchema: true`), invalid schema JSON **never renders the form**. Users/devs see `SchemaErrorView` with:

- JSON path (e.g. `fields[2].key`)
- Message, expected, actual
- Copy-all errors
- Warnings (e.g. unknown type) may still allow render with a banner

```dart
final result = const FormSchemaValidator().validate(rawJson);
if (!result.isValid) {
  for (final issue in result.errors) {
    print('${issue.path}: ${issue.message}');
  }
}

DynamicForm(
  json: rawJson,
  validateSchema: true,
  onSchemaInvalid: (result) { /* analytics */ },
);
```

Pass a pre-built `FormSchema` to skip map validation (you already own the model).

---

## DynamicForm widget API

| Parameter | Default | Description |
| --- | --- | --- |
| `json` | *(required)* | `Map`, JSON `String`, or `FormSchema` |
| `controller` | internal | External controller if you need access outside the widget |
| `theme` | `null` | `DynamicFormTheme` |
| `localizations` | English | `DynamicFormLocalizations` |
| `plugins` | empty registry | Custom renderers + media services |
| `padding` | `EdgeInsets.all(16)` | Outer padding |
| `showSubmitButton` | `true` | Show submit |
| `showResetButton` | theme | Override theme `showResetButton` |
| `submitLabel` / `resetLabel` | schema | Button labels |
| `onSubmit` | — | `(Map values)` after successful submit |
| `onChanged` | — | Values changed |
| `onFieldChanged` | — | `(key, value)` |
| `onValidationFailed` | — | `(Map errors)` |
| `onValidationSuccess` | — | `(Map values)` |
| `onSaved` | — | After save on submit |
| `onSchemaInvalid` | — | Schema failed pre-validation |
| `scrollable` | `true` | Wrap body in `SingleChildScrollView` |
| `validateSchema` | `true` | Run `FormSchemaValidator` first |
| `useSafeArea` | `true` | Wrap in `SafeArea` |
| `fieldBuilder` | `FieldBuilder()` | Advanced: custom build strategy |

---

## DynamicFormController API

### Create

```dart
final controller = DynamicFormController(
  customValidators: { 'myRule': (value, ctx) => null },
  asyncValidators: { 'uniqueEmail': (value, ctx) async => null },
  serverValidator: (value, ctx, rule) async => null,
);
```

### State

| Getter | Meaning |
| --- | --- |
| `schema` | Bound `FormSchema?` |
| `values` | Flat `Map<String, dynamic>` |
| `nestedValues` | Groups nested by key |
| `errors` | `Map<String, String>` field → message |
| `isValid` | No current errors |
| `isDirty` | User changed something |
| `isSubmitting` | Submit in flight |
| `isValidating` | Async validation in flight |
| `state` | Immutable `DynamicFormState` snapshot |

### Methods

| Method | Purpose |
| --- | --- |
| `bind(schema, {resetValues})` | Attach schema (usually done by `DynamicForm`) |
| `getValue(key)` | Read one value |
| `updateField(key, value, {validate, notifyListeners})` | Set + optional validate |
| `patchValues(map, {validate})` | Bulk update |
| `validateField` / `validate` | Sync validation |
| `validateAsync` | Sync + async + server |
| `submit({nestGroups})` | Async validate → callbacks → `true`/`false` |
| `reset` / `clear` | Defaults / null all |
| `isFieldVisible` / `isFieldEnabled` | Condition + flags |
| `addRepeatableItem` / `removeRepeatableItem` / `updateRepeatableItemField` | Repeatable CRUD |
| `registerValidator` / `registerAsyncValidator` / `setServerValidator` | Extend rules |
| `errorFor` / `fieldFor` | Lookups |
| `dispose` | If you own the controller |

Wire widget callbacks either on `DynamicForm(...)` or by assigning `controller.onSubmit = ...` before bind.

---

## Submitted values shape

Typical flat map:

```json
{
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "age": "36",
  "plan": "pro",
  "tags": ["a", "b"],
  "agree": true,
  "startDate": "2026-07-23",
  "score": 4.0,
  "color": "#2196F3",
  "avatar": {
    "path": "/tmp/a.jpg",
    "name": "a.jpg",
    "mimeType": "image/jpeg",
    "sizeBytes": 12345,
    "source": "gallery"
  },
  "location": {
    "latitude": 37.77,
    "longitude": -122.41,
    "accuracy": 10.0,
    "address": null
  },
  "references": [
    { "name": "Grace", "email": "grace@example.com" }
  ]
}
```

### MediaFileValue

| JSON in | Canonical out |
| --- | --- |
| `path` / `uri`, `name` / `fileName`, `mimeType` / `mime`, `sizeBytes` / `size`, `bytes`, `source` | `path`, `name`, `mimeType`, `sizeBytes`, `source` (+ `bytes` if present) |

### LocationValue

| JSON in | Canonical out |
| --- | --- |
| `latitude`/`lat`, `longitude`/`lng`/`lon`, `accuracy`, `altitude`, `address` | same canonical names |

Signature value is a list of stroke maps (not a PNG). Convert to an image in your app if needed.

---

## Media fields & injectable services

```dart
class MyImagePicker implements FormImagePicker {
  @override
  Future<MediaFileValue?> pickFromGallery() async {
    // Use image_picker, file_picker, etc.
    return MediaFileValue(path: '...', name: 'photo.jpg');
  }
}

final plugins = DynamicFormPluginRegistry(
  mediaServices: FormMediaServices(
    imagePicker: MyImagePicker(),
    camera: MyCamera(),
    filePicker: MyFilePicker(),
    location: MyLocation(),
  ),
);

DynamicForm(json: schema, plugins: plugins, controller: controller);
```

Interfaces:

| Interface | Method |
| --- | --- |
| `FormImagePicker` | `pickFromGallery()` → `MediaFileValue?` |
| `FormCameraCapture` | `capture()` → `MediaFileValue?` |
| `FormFilePicker` | `pickFiles({allowMultiple, allowedExtensions})` → `List<MediaFileValue>` |
| `FormLocationProvider` | `getCurrentLocation()` → `LocationValue?` |

For demos/tests:

```dart
plugins: DynamicFormPluginRegistry(mediaServices: mockMediaServices()),
```

---

## Custom field renderers (plugins)

```dart
final plugins = DynamicFormPluginRegistry();

plugins.registerRenderer('badge', (FieldRenderContext ctx) {
  return TextField(
    decoration: InputDecoration(labelText: ctx.field.label),
    onChanged: (v) => ctx.controller.updateField(ctx.field.key, v),
  );
});

DynamicForm(
  json: {
    'fields': [
      {
        'type': 'custom',
        'customType': 'badge',
        'key': 'code',
        'label': 'Badge code',
      },
    ],
  },
  plugins: plugins,
);
```

- Lookup order: `customType` / `custom_type` / `renderer`, else built-in type name.
- You can also override a built-in type by registering a renderer under that type name (e.g. `'text'`).
- `FieldRenderContext` exposes `context`, `field`, `controller`, `theme`.

---

## Theming

```dart
DynamicForm(
  json: schema,
  theme: const DynamicFormTheme(
    fieldSpacing: 20,
    borderRadius: 12,
    maxContentWidth: 640, // null = full width
    dense: false,
    animateFields: true,
    showResetButton: true,
    groupDecoration: true,
  ),
);
```

| Property | Default |
| --- | --- |
| `fieldSpacing` | `16` |
| `contentPadding` | horizontal 16 / vertical 12 |
| `borderRadius` | `8` |
| `titleStyle` / `descriptionStyle` / `labelStyle` / `errorStyle` / `helperStyle` / `groupTitleStyle` | inherit Material |
| `inputDecorationTheme` | `null` |
| `submitButtonStyle` / `resetButtonStyle` | `null` |
| `showResetButton` | `true` |
| `dense` | `false` |
| `animateFields` | `true` |
| `animationDuration` | `220ms` |
| `animationCurve` | `easeInOut` |
| `groupDecoration` | `true` |
| `groupPadding` | `16` all |
| `groupBackgroundColor` / `groupBorderColor` | `null` |
| `maxContentWidth` | `720` |

Use `DynamicFormThemeProvider.of(context)` inside custom renderers.

---

## Localization

```dart
DynamicForm(
  json: schema,
  localizations: const DynamicFormLocalizations(
    submitLabel: 'Enviar',
    resetLabel: 'Restablecer',
    requiredMessage: '{label} es obligatorio',
    emailMessage: 'Correo inválido',
    addItemLabel: 'Añadir',
    removeItemLabel: 'Quitar',
    pickImageLabel: 'Elegir imagen',
    takePhotoLabel: 'Tomar foto',
    pickFileLabel: 'Elegir archivo',
    getLocationLabel: 'Obtener ubicación',
    mediaNotConfigured: 'Servicio multimedia no configurado',
    itemLabel: 'Ítem {index}',
  ),
);
```

Templates support `{label}`, `{min}`, `{max}`, `{field}`, `{index}` via `DynamicFormLocalizations.format`.

> **Note:** Built-in sync validator default English strings are currently hardcoded in the validator engine. Prefer per-rule `"message"` in JSON for production copy, and use `DynamicFormLocalizations` for chrome (buttons, media, repeatable).

---

## Accessibility

- Fields wrap interactive controls with `Semantics`.
- Set `semanticLabel` / `semantic_label` on any field for a custom a11y name.
- `SchemaErrorView` is a live region so screen readers announce schema failures.

---

## Responsive / platform notes

| Concern | Behavior |
| --- | --- |
| Phone / tablet / desktop | Content capped by `theme.maxContentWidth` (default 720), centered |
| Narrow width (&lt; 360) | Submit / reset stack vertically |
| Keyboard | Scroll view pads `viewInsets.bottom`; drag-to-dismiss |
| Notches | `useSafeArea: true` by default |
| Android / iOS / web / desktop | Pure Flutter widgets — use host app Flutter min SDK |
| Media permissions | Your injected pickers must request OS permissions |

Package `environment`:

```yaml
sdk: ^3.5.0
flutter: ">=3.24.0"
```

---

## Example app

```bash
cd example
flutter run
```

Bundled schemas under `example/assets/schemas/`:

| File | Demonstrates |
| --- | --- |
| `simple_form.json` | Minimal text + email |
| `registration_form.json` | Phase 1 fields + length validators |
| `survey_form.json` | Number score + multiline |
| `selection_form.json` | Checkbox, switch, radio, dropdown, chips, date/time |
| `conditional_form.json` | `visibleWhen` / `enabledWhen` |
| `nested_form.json` | Groups + password `compare` |
| `media_form.json` | Image, camera, file, location + async email |
| `advanced_form.json` | Slider, rating, color, signature, repeatable, custom badge |

---

## Public API checklist

Import once:

```dart
import 'package:flutter_dynamic_form/flutter_dynamic_form.dart';
```

| Area | Types |
| --- | --- |
| UI | `DynamicForm`, `SchemaErrorView` |
| Control | `DynamicFormController`, `DynamicFormState` |
| Schema | `FormSchema`, `FormFieldSchema`, `FieldOption`, `ValidationRule` |
| Parse / validate schema | `FormSchemaParser`, `FormSchemaValidator`, `SchemaValidationResult`, `SchemaValidationIssue` |
| Conditions | `FieldCondition`, `FieldConditionGroup`, `ConditionEvaluator`, `ConditionOperator` |
| Validators | `Validators`, `FieldValidator`, `AsyncFieldValidator`, `ValidationContext`, `ValidatorType` |
| Theme / l10n | `DynamicFormTheme`, `DynamicFormLocalizations` (+ providers) |
| Plugins | `DynamicFormPluginRegistry`, `FieldRenderer`, `FieldRenderContext`, `FormMediaServices`, media interfaces, `mockMediaServices()` |
| Values | `MediaFileValue`, `LocationValue` |
| Errors | `DynamicFormException`, `FormSchemaParseException`, `ValidatorConfigException` |
| Enums | `FieldType`, `ValidatorType`, `ConditionOperator`, `SchemaIssueSeverity` |

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Red “Invalid form schema” screen | Read paths in `SchemaErrorView`; fix JSON (`key`, `type`, `fields`, duplicates) |
| Form empty / spinner | Schema failed parse after validation — check `onSchemaInvalid` / console |
| Media button says not configured | Pass `plugins` with `FormMediaServices` or `mockMediaServices()` |
| Async rules never run | Use `validateAsync()` / `submit()`, not sync `validate()` |
| Custom field blank | Register renderer name matching `customType` |
| Duplicate key error | Group children share the global key space — rename keys |
| Compare always fails | Ensure compared field `key` matches and values update before validate |
| Want nested API payload | `await controller.submit(nestGroups: true)` or read `nestedValues` |
| Hide values of invisible fields | Filter `values` yourself before API call |

### Validate only schema (CI / backend)

```dart
test('registration schema is valid', () {
  final json = jsonDecode(File('schemas/registration.json').readAsStringSync());
  final result = const FormSchemaValidator().validate(json);
  expect(result.isValid, isTrue, reason: result.errors.join('\n'));
});
```

---

## Docs & license

| Doc | Purpose |
| --- | --- |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [MIGRATION.md](MIGRATION.md) | Breaking changes between versions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Vulnerability reporting |
| [status.md](status.md) | Internal phase / roadmap status |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community rules |
| [LICENSE](LICENSE) | MIT |

```bash
flutter analyze
flutter test
dart pub publish --dry-run
```

---

MIT © contributors — see [LICENSE](LICENSE).
