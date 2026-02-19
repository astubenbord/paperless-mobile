import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/model/color_scheme_option.dart';
import 'package:paperless_mobile/core/model/file_download_type.dart';

part 'global_settings.g.dart';

@HiveType(typeId: HiveTypeIds.globalSettings)
class GlobalSettings with HiveObjectMixin {
  @HiveField(0)
  String preferredLocaleSubtag;

  @HiveField(1)
  ThemeMode preferredThemeMode;

  @HiveField(2)
  ColorSchemeOption preferredColorSchemeOption;

  @HiveField(3)
  bool showOnboarding;

  @HiveField(4)
  String? loggedInUserId;

  @HiveField(5)
  FileDownloadType defaultDownloadType;

  @HiveField(6)
  FileDownloadType defaultShareType;

  @HiveField(7, defaultValue: false)
  bool enforceSinglePagePdfUpload;

  @HiveField(8, defaultValue: false)
  bool skipDocumentPreprarationOnUpload;

  @HiveField(9, defaultValue: false)
  bool disableAnimations;

  @HiveField(10, defaultValue: true)
  bool showAiSuggestions;

  @HiveField(11, defaultValue: '')
  String aiServerUrl;

  @HiveField(12, defaultValue: '')
  String aiApiKey;

  GlobalSettings({
    required this.preferredLocaleSubtag,
    this.preferredThemeMode = ThemeMode.system,
    this.preferredColorSchemeOption = ColorSchemeOption.classic,
    this.showOnboarding = true,
    this.loggedInUserId,
    this.defaultDownloadType = FileDownloadType.alwaysAsk,
    this.defaultShareType = FileDownloadType.alwaysAsk,
    this.enforceSinglePagePdfUpload = false,
    this.skipDocumentPreprarationOnUpload = false,
    this.disableAnimations = false,
    this.showAiSuggestions = true,
    this.aiServerUrl = '',
    this.aiApiKey = '',
  });
}
