# Migration Guide

## 0.3.x → 1.0.0

- Prefer `flutter_dynamic_form: ^1.0.0`.
- `submit()` now runs **async/server validators** before invoking callbacks. Ensure any registered async validators complete promptly.
- `DynamicFormState` includes a new `isValidating` flag.
- Media fields require `FormMediaServices` via `DynamicForm(plugins: …)` for real device picking; without services, buttons show a configuration hint (or use `mockMediaServices()` in demos).

## 0.1.x → 0.3.0

- Additive only: new field types and condition keys. Existing Phase 1 schemas remain valid.
