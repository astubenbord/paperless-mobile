import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/correspondent_repository.dart';
import 'package:paperless_mobile/core/repository/custom_field_repository.dart';
import 'package:paperless_mobile/core/repository/document_repository.dart';
import 'package:paperless_mobile/core/repository/document_type_repository.dart';
import 'package:paperless_mobile/core/repository/inbox_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/search_repository.dart';
import 'package:paperless_mobile/core/repository/server_statistics_repository.dart';
import 'package:paperless_mobile/core/repository/storage_path_repository.dart';
import 'package:paperless_mobile/core/repository/tag_repository.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/core/store/slices/local_user_account.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:provider/provider.dart';

extension ContextExtensions on BuildContext {
  LocalStore get localStore => read<LocalStore>();
  LocalStore get localStore$ => watch<LocalStore>();

  String? get loggedInAppUserId$ => localStore$.state.loggedInAppUserId;
  String? get loggedInAppUserId => localStore.state.loggedInAppUserId;

  GlobalSettings get globalSettings$ => localStore$.state.globalSettings;

  Map<String, LocalUserData> get localUserData$ =>
      localStore$.state.localUserData;
  Map<String, LocalUserData> get localUserData =>
      localStore.state.localUserData;

  LocalUserData get loggedInUserData$ => localUserData$[loggedInAppUserId$]!;
  LocalUserData get loggedInUserData => localUserData[loggedInAppUserId]!;

  DocumentRepository get documentRepository => read<DocumentRepository>();
  SavedViewRepository get savedViewRepository => read<SavedViewRepository>();
  CorrespondentRepository get correspondentRepository =>
      read<CorrespondentRepository>();
  DocumentTypeRepository get documentTypeRepository =>
      read<DocumentTypeRepository>();
  TagRepository get tagRepository => read<TagRepository>();
  StoragePathRepository get storagePathRepository =>
      read<StoragePathRepository>();
  CustomFieldsRepository get customFieldRepository =>
      read<CustomFieldsRepository>();
  InboxRepository get inboxRepository => read<InboxRepository>();
  SearchRepository get searchRepository => read<SearchRepository>();
  ServerStatisticsRepository get serverStatisticsRepository =>
      read<ServerStatisticsRepository>();
  DocumentFilter get currentDocumentFilter$ =>
      loggedInUserData$.appState.currentDocumentFilter;
  DocumentFilter get currentDocumentFilter => localStore
      .state
      .localUserData[loggedInAppUserId]!
      .appState
      .currentDocumentFilter;

  LocalUserAccount get loggedInUser$ => watch<LocalUserAccount>();
  LocalUserAccount get loggedInUser => read<LocalUserAccount>();

  UiSettingsView get uiSettings$ =>
      watch<LocalUserAccount>().profile.uiSettings;
  UiSettingsView get uiSettings => read<LocalUserAccount>().profile.uiSettings;

  String get dateLocale {
    final remoteLocale = uiSettings.settings?.dateDisplay?.dateLocale;
    if (remoteLocale == null || remoteLocale.isEmpty) {
      return Localizations.localeOf(this).toLanguageTag();
    }

    return remoteLocale;
  }

  ///
  /// Returns the date format to be used for displaying dates in the app, based on the user's UI settings.
  /// If the date is not set in the UI settings, it falls back to a default date format.
  ///
  DateFormat get displayDateFormat {
    if (dateLocale == 'iso-8601') {
      return apiDateFormat;
    }
    final type =
        uiSettings.settings?.dateDisplay?.dateFormat ??
        UiSettingsViewSettingsDateDisplayFormat.medium;
    return switch (type) {
      UiSettingsViewSettingsDateDisplayFormat.short => DateFormat.yMd(
        dateLocale,
      ),
      UiSettingsViewSettingsDateDisplayFormat.medium => DateFormat.yMMMd(
        dateLocale,
      ),
      UiSettingsViewSettingsDateDisplayFormat.long => DateFormat.yMMMMd(
        dateLocale,
      ),
    };
  }

  void refetchLabels() {
    if (uiSettings.canViewCorrespondents) {
      correspondentRepository.getAllQuery().refetch();
    }
    if (uiSettings.canViewDocumentTypes) {
      documentTypeRepository.getAllQuery().refetch();
    }
    if (uiSettings.canViewTags) {
      tagRepository.getAllQuery().refetch();
    }

    if (uiSettings.canViewStoragePaths) {
      storagePathRepository.getAllQuery().refetch();
    }
    if (uiSettings.canViewCustomFields) {
      customFieldRepository.getAllQuery().refetch();
    }
  }
}
