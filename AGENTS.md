# Paperless Mobile - Agent Instructions

Flutter client for [paperless-ngx](https://github.com/paperless-ngx/paperless-ngx). Dart SDK `>=3.8.0`, Flutter pinned to `3.41.0` via FVM (`.fvmrc`). Prefer `fvm flutter` / `fvm dart` when FVM is available.

## Commands

- Install and generate: `scripts/install_dependencies.sh` (runs `dart pub get`, `flutter gen-l10n`, `build_runner`).
- Codegen after changing `@freezed`, `@JsonSerializable`, Hive, `go_router_builder`, or mockito classes: `dart run build_runner build --delete-conflicting-outputs`.
- Localization after editing ARB files: `flutter gen-l10n`.
- Analyze: `dart analyze` (config in `analysis_options.yaml`, based on `flutter_lints`).
- Format: `dart format .`. The pre-commit hook (`hooks/pre-commit`, installed via `scripts/install_git_hooks.sh`) rejects unformatted staged files, analyzer errors, and merge conflict markers.
- Tests: `flutter test` (unit and widget tests under `test/`). Integration tests live in `integration_test/`.
- Generated code: never edit `*.g.dart`, `*.freezed.dart`, or anything under `lib/generated/` by hand. Regenerate instead. `lib/generated/` also holds the OpenAPI client output and is produced by `scripts/generate_models.sh` from `specs/paperless-ngx-api-v9.yaml`.

## Project structure

```
lib/
  main.dart            App bootstrap: Bloc observer, storage, DI, runApp
  constants.dart, keys.dart, theme.dart
  api/                 Paperless REST client layer (Dio), models, interceptors, cached-query extensions
    models/            API models and query parameters
    interceptor/       Dio interceptors (auth, logging, etc.)
    extensions/        e.g. cached_query_extensions.dart
  core/
    bloc/              Shared cubit/state primitives (BaseState, LoadingStatus, ConnectivityCubit, MyBlocObserver)
    repository/        Data access on top of api/. CrudRepository plus one repository per entity
    store/             LocalStore (HydratedBloc-backed) and EncryptedLocalStore (flutter_secure_storage)
      slices/          Persisted state slices (global settings, user credentials, per-user data)
      bloc/            Builders that expose store state to the widget tree
    security/          SessionManager
    service/           Services: connectivity, file, dio file download, GitHub issues
    translation/       Mappers from domain enums/error codes to localized strings
    extensions/, util/, widgets/, exception/, model/, interceptor/, global/
  features/<feature>/  One folder per feature, typically cubit/ or bloc/, model/, service/, view/ (pages and widgets)
  routing/
    routes.dart, navigation_keys.dart
    routes/            go_router routes (typed GoRouteData with generated *.g.dart)
    routes/shells/     Shell routes (e.g. authenticated shell, branches for bottom navigation)
    utils/
  l10n/                ARB files (intl_en.arb is the template)
  generated/           Generated: l10n output (generated/l10n/) and OpenAPI client
  translations/        Locale extensions for localized strings
test/                  Unit and widget tests, fixtures under test/fixtures/
integration_test/      Integration tests
scripts/               Install, codegen, Crowdin helpers
specs/                 OpenAPI spec
hooks/                 Git hooks
```

Dependency direction: `features` → `core/repository` → `api`. Views should not call `api/` directly. Repositories and services are injected through `RepositoryProvider` / `MultiRepositoryProvider` and `Provider`, both wired in `main.dart` and `features/home/view/home_shell_widget.dart`.

## State management

- **Feature state: `flutter_bloc`.** Use `Cubit` for most features. Use `Bloc` only when event-driven transitions justify it. Provide with `BlocProvider`, read with `context.read<T>()` for actions and `context.watch<T>()` or `BlocBuilder` / `BlocSelector` for rendering.
- **States:** Model as immutable classes. Use `Equatable` (`EquatableMixin`) for hand-written states, or `@freezed` sealed classes for states with many variants. Keep state minimal, and derive values in the view instead of storing duplicates.
- **Loading and errors:** Use `LoadingStatus` (`initial`, `loading`, `loaded`, `error`) and `BaseState<T>` for simple async state. Surface errors through the localized error mappers in `core/translation/`, not raw exception messages.
- **Server data caching: `cached_query_flutter`.** Repositories expose `Query<T>` and `Mutation<T, R>` objects (see `CrudRepository`). Views and cubits consume them through query state, and `CachedQueryExtensions.isLoadingInitial` tells "first load" apart from refetching. After a mutation, invalidate the affected query keys so lists and details stay consistent. Repositories emit change events through `ChangeNotifierMixin` (`ChangeType.create | update | delete`) so other repositories and features can react.
- **Persistent local state: `hydrated_bloc` and `hive_ce`.** `LocalStore` is a `HydratedBloc` persisted with `HydratedStorage`. Sensitive data (credentials, tokens) goes to `EncryptedLocalStore` backed by `flutter_secure_storage`. Do not store secrets in `LocalStore`.
- **Session and auth:** `AuthenticationCubit` owns login state. `SessionManager` owns the active API session. Multi-user switching is handled through per-user slices in the store.
- **Observability:** `Bloc.observer = MyBlocObserver()` is set in `main.dart`. Use the project logger (`features/logging/data/logger.dart`) with `logger.fe(...)` for errors and include `className` and `methodName`.
- **Legacy:** `provider` and `ChangeNotifier` exist in some places (for example `session_manager.dart`). Do not add new `ChangeNotifier`-based state. Use a Cubit instead.

## Routing

- Use `go_router` with `go_router_builder`. Routes are typed `GoRouteData` classes in `lib/routing/routes/`. Add the class, run build_runner, then navigate with the generated type, for example `DocumentsRoute(...).go(context)`. Do not build route paths as raw strings.
- Navigator keys are defined in `lib/routing/navigation_keys.dart`. Reuse them rather than creating new global keys.
- Check the router's redirect logic before adding auth or access checks inside pages.

## Translations (l10n)

Localization uses Flutter's ARB pipeline, with Crowdin as the translation platform.

- **Template:** `lib/l10n/intl_en.arb` is the only file you edit for new strings. Configuration is in `l10n.yaml`: output class `S`, generated files in `lib/generated/l10n/`, untranslated report in `untranslated_messages.txt` (gitignored).
- **Adding a string:** Add the key to `intl_en.arb` with an `@key` metadata block that has a `description` for translators. Keep keys in camelCase. Parameters use ICU placeholders with `@key` metadata that declares their `placeholders`.
- **Do not edit the other ARB files** (`intl_de.arb`, `intl_fr.arb`, etc.). Translations come from Crowdin.
- **Using a string:** `S.of(context)!.myKey`. Use `S.of(context)!` in widgets. Outside widgets, pass the `S` instance or a `BuildContext` in.
- **Regenerate:** Run `flutter gen-l10n` after every ARB change. The generated `lib/generated/l10n/` output is gitignored and must not be edited.
- **Sync with Crowdin:**
  - `scripts/upload_translation_source.sh` uploads `intl_en.arb` as the source file. Maintainers run this after merging new strings.
  - `scripts/update_translations.sh` downloads source and translated files, then runs `flutter gen-l10n`.
  - Credentials come from `crowdin_credentials.yml`, which is gitignored. Do not commit it.
- **Enum and error text:** Map enums and error codes to strings in `lib/core/translation/*_localization_mapper.dart` instead of hard-coding English.
- **Supported locales:** ar, ca, cs, de, en, es, fr, it, nl, pl, pt, ro, ru, sl, tr. The `en` locale has regional variants in `lib/translations/`.
- **Do not hard-code user-facing text** in widgets, dialogs, or snackbars.

## Best practices

- **Keep changes small and focused.** Match the existing feature folder layout when adding a feature.
- **Null safety and immutability:** Prefer `final`, `const` constructors, and immutable state. Use `copyWith` on states.
- **Async:** Check `mounted` (or `context.mounted`) after every `await` before using `BuildContext`.
- **Lifecycle:** Close cubits and streams you create. Use `BlocProvider(create:)` so Bloc manages closing.
- **Errors:** Catch at repository or cubit boundaries. Log with the project logger. Map to user-facing localized messages. Never swallow errors silently.
- **Repositories:** Extend `CrudRepository` for standard entity CRUD. Keep API details in `api/`, and keep caching and invalidation in `core/repository/`.
- **Models:** Use `json_serializable` with the project's `build.yaml` settings (`field_rename: snake`, `explicit_to_json: true`). Add `equatable` where value equality matters.
- **Theming:** Use `Theme.of(context)` and the color scheme from `theme.dart`. Do not hard-code colors or text styles. Support dark mode and dynamic color (`dynamic_color`).
- **Accessibility:** Provide semantic labels for icon-only buttons. Respect text scaling. Helpers live in `lib/accessibility/`.
- **Platform code:** Android and iOS config lives in `android/` and `ios/`. Keep platform-specific code behind services in `core/service/` or `features/*/services/`.
- **Tests:** Add unit tests for cubits (follow `test/src/bloc/document_cubit_test.dart`; `bloc_test` is not a dependency) and repositories with mocks (`mockito`, generated via build_runner). Use fixtures in `test/fixtures/`.
- **Commits:** Use conventional commits, for example `feat: ...`, `fix(scope): ...`, `chore: ...`. The existing history follows this style.
- **Versioning and releases:** Use the `version` skill in `.agents/skills/version/` for version bumps and changelog stubs. Do not change `version:` in `pubspec.yaml` manually for releases.

## Things to avoid

- Editing generated files (`*.g.dart`, `*.freezed.dart`, `lib/generated/`).
- Editing non-English ARB files.
- Calling the API directly from widgets or cubits. Go through repositories.
- Storing secrets in `LocalStore` or in plain `SharedPreferences`.
- Adding new `ChangeNotifier` or `setState`-heavy state for features that should be Cubits.
- Introducing new dependencies without checking `pubspec.yaml` first. Some functionality already has a package here (`cached_query_flutter`, `dio`, `go_router`, `hive_ce`, `flutter_form_builder`, `pdfrx`, `fl_chart`).
- Skipping `flutter gen-l10n`, `build_runner`, or `dart format` before committing.
