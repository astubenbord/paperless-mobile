# Paperless Mobile Directory Structure Refactoring Plan

## Status: COMPLETE

All 17 steps executed successfully. Verified with `build_runner`, `flutter analyze` (0 errors in lib/), and both debug and release APK builds.

---

## Commit 1: Move misplaced models from features/ to core/model/ (Steps 1-5) -- DONE

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

## Commit 4: Move accessibility/, helpers/, translations/ into core/ (Steps 11-13) -- DONE

- [x] **Step 11** -- `lib/accessibility/*.dart` -> `lib/core/accessibility/*.dart`
- [x] **Step 12** -- `lib/helpers/` files into core/:
  - `format_helpers.dart` -> `core/util/format_helpers.dart`
  - `message_helpers.dart` -> `core/util/message_helpers.dart`
  - `permission_helpers.dart` -> `core/util/permission_helpers.dart`
  - `connectivity_aware_action_wrapper.dart` -> `core/widgets/connectivity_aware_action_wrapper.dart`
- [x] **Step 13** -- `lib/translations/app_localizations_en_extensions.dart` -> `lib/core/translation/app_localizations_en_extensions.dart`

---

## Commit 5: Move paged_document_view to core/paging/ + saved_view merge + widget extraction (Steps 14-17) -- DONE

- [x] **Step 14** -- Move all 3 files from `features/paged_document_view/` -> `core/paging/`
- [x] **Step 15** -- Move 5 files from `features/saved_view_details/` -> `features/saved_view/` and 3 saved_view widgets from `features/documents/view/widgets/saved_views/` -> `features/saved_view/view/widgets/`
- [x] **Step 16** -- `features/documents/view/pages/document_view.dart` -> `core/widgets/document_view.dart`
- [x] **Step 17a** -- `core/workarounds/colored_chip.dart` -> `core/widgets/colored_chip.dart`
- [x] **Step 17b** -- `core/delegate/customizable_sliver_persistent_header_delegate.dart` -> `core/widgets/customizable_sliver_persistent_header_delegate.dart`
- [x] **Step 17d** -- `core/exception/server_message_exception.dart` -> `core/model/server_message_exception.dart`
- [x] Deleted empty directories: `core/workarounds/`, `core/delegate/`, `core/exception/`, `features/saved_view_details/`, `features/paged_document_view/`, `features/documents/view/widgets/saved_views/`

---

## Commit 6: Update remaining imports -- DONE

- [x] Fixed duplicate import in `scanner_page.dart`
- [x] Fixed stale import in `integration_test/login_integration_test.dart`

---

## Verification Results

- `build_runner`: 61 outputs generated (lib/) + 73 outputs (packages/paperless_api/) -- all clean
- `flutter analyze lib/`: 0 errors, 6 pre-existing warnings, 9 pre-existing infos
- `flutter build apk --debug`: SUCCESS
- `flutter build apk --release`: SUCCESS (183.7MB)
