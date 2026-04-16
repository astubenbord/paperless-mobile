import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/store/slices/local_user_account.dart';
import 'package:paperless_mobile/features/settings/view/widgets/app_logs_tile.dart';
import 'package:paperless_mobile/features/settings/view/widgets/biometric_authentication_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/changelogs_tile.dart';
import 'package:paperless_mobile/features/settings/view/widgets/clear_storage_settings.dart';
import 'package:paperless_mobile/features/settings/view/widgets/color_scheme_option_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/default_download_file_type_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/default_share_file_type_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/enforce_pdf_upload_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/language_selection_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/skip_document_prepraration_on_share_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/theme_mode_setting.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.loggedInUser$;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context)!.settings)),
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
          _buildSectionHeader(context, S.of(context)!.storage),
          const ClearCacheSetting(),
          _buildSectionHeader(context, S.of(context)!.misc),
          const AppLogsTile(),
          const ChangelogsTile(),
        ],
      ),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [_buildFooter(context, currentUser)],
      persistentFooterDecoration: BoxDecoration(),
    );
  }

  Widget _buildFooter(BuildContext context, LocalUserAccount currentUser) {
    final host = currentUser.serverUrl.replaceFirst(RegExp(r"https?://"), "");
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "${S.of(context)!.loggedInAs(currentUser.profile.uiSettings.user.username)}@$host",
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          QueryBuilder(
            query: context.serverStatisticsRepository.serverInformationQuery,
            builder: (context, state) {
              if (state.isError) {
                return Text(
                  S.of(context)!.errorRetrievingServerVersion,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                );
              }
              if (state.isLoading) {
                return Text(
                  S.of(context)!.resolvingServerVersion,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                );
              }
              final serverData = state.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${S.of(context)!.paperlessServerVersion}'
                    ' ${serverData.version} (API v${currentUser.apiVersion})',
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
                            style: Theme.of(context).textTheme.labelSmall!
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
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
