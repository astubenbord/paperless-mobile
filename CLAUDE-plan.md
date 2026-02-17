# Paperless Mobile Directory Structure Refactoring Plan

## Context

The `lib/` directory has several structural issues: `core/` imports from `features/` (inverted dependencies), orphan top-level directories, misclassified "features" that are really shared infrastructure, and fragmented/inconsistent feature organization. This plan fixes all of these in 17 steps, grouped into 7 commits.

## Verification After Each Step

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

## Commit 1: Move misplaced models from features/ to core/model/ (Steps 1-5) -- DONE

Fixes the inverted dependency problem where `core/` imports from `features/`.

- [x] **Step 1** -- `features/settings/model/view_type.dart` -> `core/model/view_type.dart`
- [x] **Step 2** -- `features/settings/model/file_download_type.dart` -> `core/model/file_download_type.dart`
- [x] **Step 3** -- `features/settings/model/color_scheme_option.dart` -> `core/model/color_scheme_option.dart`
- [x] **Step 4** -- `features/login/model/client_certificate.dart` -> `core/model/client_certificate.dart`
- [x] **Step 5** -- `features/login/model/reachability_status.dart` -> `core/model/reachability_status.dart`

---

## Commit 2: Move logger to core/ (Step 6) -- DONE

- [x] **Step 6** -- `features/logging/data/logger.dart` -> `core/logging/logger.dart` and `features/logging/models/formatted_log_message.dart` -> `core/logging/formatted_log_message.dart`

---

## Commit 3: Consolidate orphan top-level files (Steps 7-10) -- DONE

- [x] **Step 7** -- `features/settings/view/widgets/global_settings_builder.dart` -> `core/widgets/global_settings_builder.dart`
- [x] **Step 8** -- Merge `lib/constants.dart` into `lib/core/global/constants.dart`
- [x] **Step 9** -- `lib/theme.dart` -> `lib/core/theme.dart`
- [x] **Step 10** -- `lib/keys.dart` -> `lib/features/login/view/test_keys.dart`

---

## Commit 4: Move accessibility/, helpers/, translations/ into core/ (Steps 11-13) -- IN PROGRESS

- [x] **Step 11** -- `lib/accessibility/*.dart` -> `lib/core/accessibility/*.dart`
- [ ] **Step 12** -- `lib/helpers/` files into core/:
  - `format_helpers.dart` -> `core/util/format_helpers.dart` (4 importers)
  - `message_helpers.dart` -> `core/util/message_helpers.dart` (23 importers)
  - `permission_helpers.dart` -> `core/util/permission_helpers.dart` (3 importers)
  - `connectivity_aware_action_wrapper.dart` -> `core/widgets/connectivity_aware_action_wrapper.dart` (9 importers)
- [x] **Step 13** -- `lib/translations/app_localizations_en_extensions.dart` -> `lib/core/translation/app_localizations_en_extensions.dart`

---

## Commit 5: Move paged_document_view to core/paging/ (Step 14)

- [ ] **Step 14** -- Move all 3 files from `features/paged_document_view/` -> `core/paging/`
  - `document_paging_bloc_mixin.dart`, `paged_documents_state.dart`, `document_paging_view_mixin.dart`
  - Update imports in 12 files across 7 features

---

## Commit 6: Merge saved_view_details into saved_view (Step 15)

- [ ] **Step 15** -- Move 5 files from `features/saved_view_details/` -> `features/saved_view/` (cubit + view)
  - Also move 3 saved_view widgets from `features/documents/view/widgets/saved_views/` -> `features/saved_view/view/widgets/`
  - Update imports in landing_page, documents_page, and internal references
  - Delete empty `features/saved_view_details/` and `features/documents/view/widgets/saved_views/`

---

## Commit 7: Extract shared widget + flatten single-file dirs (Steps 16-17)

- [ ] **Step 16** -- `features/documents/view/pages/document_view.dart` -> `core/widgets/document_view.dart`
  - Update imports in 3 files (documents_route, document_edit_page, scanner_page)

- [ ] **Step 17a** -- `core/workarounds/colored_chip.dart` -> `core/widgets/colored_chip.dart` (7 importers)

- [ ] **Step 17b** -- `core/delegate/customizable_sliver_persistent_header_delegate.dart` -> `core/widgets/customizable_sliver_persistent_header_delegate.dart` (1 importer)

- [ ] **Step 17d** -- `core/exception/server_message_exception.dart` -> `core/model/server_message_exception.dart` (3 importers)

- [ ] Delete empty directories: `core/workarounds/`, `core/delegate/`, `core/exception/`

---

## Key Files to Watch

| File | Why |
|------|-----|
| `core/database/hive/hive_config.dart` | Central Hive config -- touched by steps 1-4, must verify adapter registration still works |
| `core/database/tables/global_settings.dart` | Has `part .g.dart` -- must regenerate after steps 2-3 |
| `core/database/tables/local_user_app_state.dart` | Has `part .g.dart` -- must regenerate after step 1 |
| `helpers/message_helpers.dart` | 23 importers -- largest single batch of import updates (step 12) |
| `build.yaml` / `l10n.yaml` | Verify no path references break (l10n.yaml only references `lib/l10n/` which we don't touch) |

## Execution Strategy

For each file move:
1. `git mv old_path new_path`
2. Project-wide find-and-replace of the old package import path -> new path
3. Run `build_runner` if file has `.g.dart` / `.freezed.dart`
4. Run `flutter analyze` to verify

Total: ~35 files moved, ~100+ import updates across ~287 Dart files.
