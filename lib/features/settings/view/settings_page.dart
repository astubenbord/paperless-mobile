import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/features/settings/view/widgets/app_logs_tile.dart';
import 'package:paperless_mobile/features/settings/view/widgets/biometric_authentication_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/changelogs_tile.dart';
import 'package:paperless_mobile/features/settings/view/widgets/clear_storage_settings.dart';
import 'package:paperless_mobile/features/settings/view/widgets/color_scheme_option_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/default_download_file_type_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/default_share_file_type_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/disable_animations_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/enforce_pdf_upload_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/language_selection_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/skip_document_prepraration_on_share_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/theme_mode_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/user_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, S.of(context)!.appearance),
          const LanguageSelectionSetting(),
          const ThemeModeSetting(),
          const ColorSchemeOptionSetting(),
          _buildSectionHeader(context, S.of(context)!.security),
          const BiometricAuthenticationSetting(),
          _buildSectionHeader(context, S.of(context)!.behavior),
          const DefaultDownloadFileTypeSetting(),
          const DefaultShareFileTypeSetting(),
          const EnforcePdfUploadSetting(),
          const SkipDocumentPreprationOnShareSetting(),
          _buildSectionHeader(context, S.of(context)!.suggestions.trim()),
          const _ShowAiSuggestionsSetting(),
          _buildSectionHeader(context, S.of(context)!.storage),
          const ClearCacheSetting(),
          _buildSectionHeader(context, 'Accessibility'),
          const DisableAnimationsSetting(),
          _buildSectionHeader(context, S.of(context)!.misc),
          const AppLogsTile(),
          const ChangelogsTile(),
        ],
      ),
      bottomNavigationBar: UserAccountBuilder(
        builder: (context, user) {
          assert(user != null);
          final host = user!.serverUrl.replaceFirst(RegExp(r"https?://"), "");
          return ListTile(
            title: Text(
              "${S.of(context)!.loggedInAs(user.paperlessUser.username)}@$host",
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            subtitle: FutureBuilder<PaperlessServerInformationModel>(
              future: context
                  .read<PaperlessServerStatsApi>()
                  .getServerInformation(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    S.of(context)!.errorRetrievingServerVersion,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  );
                }
                if (!snapshot.hasData) {
                  return Text(
                    S.of(context)!.resolvingServerVersion,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  );
                }
                final serverData = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${S.of(context)!.paperlessServerVersion}'
                      ' ${serverData.version} (API v${serverData.apiVersion})',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (serverData.isUpdateAvailable) ...[
                      SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.labelSmall!,
                          text: '${S.of(context)!.newerVersionAvailable} ',
                          children: [
                            TextSpan(
                              text: serverData.latestVersion,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                    decoration: TextDecoration.underline,
                                    color: CupertinoColors.link,
                                    decorationColor: CupertinoColors.link,
                                  ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  launchUrlString(
                                    "https://github.com/paperless-ngx/paperless-ngx/releases/tag/${serverData.latestVersion}",
                                  );
                                },
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _ShowAiSuggestionsSetting extends StatelessWidget {
  const _ShowAiSuggestionsSetting();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<GlobalSettings>>(
      valueListenable:
          Hive.box<GlobalSettings>(HiveBoxes.globalSettings).listenable(),
      builder: (context, box, _) {
        final settings = box.getValue()!;
        return SwitchListTile(
          title: Text(S.of(context)!.suggestions.trim()),
          subtitle: Text(S.of(context)!.showAiSuggestionsDescription),
          value: settings.showAiSuggestions,
          onChanged: (value) {
            settings.showAiSuggestions = value;
            box.setValue(settings);
          },
        );
      },
    );
  }
}
