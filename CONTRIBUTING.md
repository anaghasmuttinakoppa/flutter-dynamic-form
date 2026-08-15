# Contributing to flutter_dynamic_form

Thanks for helping improve this package. Please follow the process below so we can keep quality high and ship phase-by-phase.

## Development principles

- Complete **one phase at a time** — do not jump ahead on the roadmap.
- Never skip tests or documentation updates.
- Follow Effective Dart, SOLID, DRY, and KISS.
- Prefer immutable models and short, focused classes.
- Update `status.md` whenever progress changes.

## Getting started

1. Fork and clone the repository.
2. Run `flutter pub get` at the package root.
3. Run `cd example && flutter pub get`.
4. Verify: `flutter analyze` and `flutter test`.

## Workflow

1. Open an issue (or claim an existing one) describing the change.
2. Create a branch: `feature/<short-name>` or `fix/<short-name>`.
3. Implement, then:
   - Fix analyzer warnings
   - Add / update unit and widget tests
   - Update README / CHANGELOG when user-facing
   - Update `status.md`
4. Open a pull request against `main`.

## Commit messages

Prefer concise, imperative subjects:

- `add phone validator edge cases`
- `fix number field parsing for decimals`
- `docs: clarify controller API`

## Code review checklist

- [ ] Tests cover the change
- [ ] Public API is documented
- [ ] No analyzer issues
- [ ] `status.md` and `CHANGELOG.md` updated when appropriate
- [ ] Example still runs for UI-facing changes

## Reporting bugs

Include Flutter/Dart versions, a minimal JSON schema, expected vs actual behavior, and (if possible) a failing test.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
