import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_state.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';
import 'package:paperless_mobile/features/inbox/view/pages/inbox_page.dart';
import 'package:paperless_mobile/features/labels/bloc/global_state_bloc_provider.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/scan/bloc/document_scanner_cubit.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/view/settings_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InfoDrawer extends StatelessWidget {
  final VoidCallback? afterInboxClosed;

  const InfoDrawer({Key? key, this.afterInboxClosed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(16.0),
        bottomRight: Radius.circular(16.0),
      ),
      child: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              padding: const EdgeInsets.only(
                top: 8,
                left: 8,
                bottom: 0,
                right: 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logos/paperless_logo_white.png',
                        height: 32,
                        width: 32,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ).padded(const EdgeInsets.only(right: 8.0)),
                      Text(
                        S.of(context).appTitleText,
                        style: Theme.of(context).textTheme.headline5?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: BlocBuilder<PaperlessServerInformationCubit,
                        PaperlessServerInformationState>(
                      builder: (context, state) {
                        if (!state.isLoaded) {
                          return Container();
                        }
                        final info = state.information!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                S.of(context).appDrawerHeaderLoggedInAsText +
                                    (info.username ?? '?'),
                                style: Theme.of(context).textTheme.bodyText2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    state.information!.host ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodyText2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '${S.of(context).serverInformationPaperlessVersionText} ${info.version} (API v${info.apiVersion})',
                                    style: Theme.of(context).textTheme.caption,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            ListTile(
              title: Text(S.of(context).bottomNavInboxPageLabel),
              leading: const Icon(Icons.inbox),
              onTap: () => _onOpenInbox(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(
                S.of(context).appDrawerSettingsLabel,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: getIt<ApplicationSettingsCubit>(),
                    child: const SettingsPage(),
                  ),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text(S.of(context).appDrawerReportBugLabel),
              onTap: () {
                launchUrlString(
                    'https://github.com/astubenbord/paperless-mobile/issues/new');
              },
            ),
            const Divider(),
            AboutListTile(
              icon: const Icon(Icons.info),
              applicationIcon: const ImageIcon(
                  AssetImage('assets/logos/paperless_logo_green.png')),
              applicationName: 'Paperless Mobile',
              applicationVersion:
                  kPackageInfo.version + '+' + kPackageInfo.buildNumber,
              aboutBoxChildren: [
                Text(
                    '${S.of(context).aboutDialogDevelopedByText} Anton Stubenbord'),
                Link(
                  uri: Uri.parse(
                      'https://github.com/astubenbord/paperless-mobile'),
                  builder: (context, followLink) => GestureDetector(
                    onTap: followLink,
                    child: Text(
                      'https://github.com/astubenbord/paperless-mobile',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Credits',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildOnboardingImageCredits(),
              ],
              child: Text(S.of(context).appDrawerAboutLabel),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(S.of(context).appDrawerLogoutLabel),
              onTap: () {
                try {
                  BlocProvider.of<AuthenticationCubit>(context).logout();
                  getIt<DocumentsCubit>().reset();
                  getIt<CorrespondentCubit>().reset();
                  getIt<DocumentTypeCubit>().reset();
                  getIt<TagCubit>().reset();
                  getIt<DocumentScannerCubit>().reset();
                } on PaperlessServerException catch (error, stackTrace) {
                  showErrorMessage(context, error, stackTrace);
                }
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Future<void> _onOpenInbox(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlobalStateBlocProvider(
          additionalProviders: [
            BlocProvider<InboxCubit>.value(
              value: getIt<InboxCubit>()..loadInbox(),
            ),
          ],
          child: const InboxPage(),
        ),
        maintainState: false,
      ),
    );
    afterInboxClosed?.call();
  }

  Link _buildOnboardingImageCredits() {
    return Link(
      uri: Uri.parse(
          'https://www.freepik.com/free-vector/business-team-working-cogwheel-mechanism-together_8270974.htm#query=setting&position=4&from_view=author'),
      builder: (context, followLink) => Wrap(
        children: [
          const Text('Onboarding images by '),
          GestureDetector(
            onTap: followLink,
            child: Text(
              'pch.vector',
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
          const Text(' on Freepik.')
        ],
      ),
    );
  }
}
