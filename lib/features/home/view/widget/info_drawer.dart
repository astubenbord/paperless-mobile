import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_cubit.dart';
import 'package:paperless_mobile/core/bloc/paperless_server_information_state.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/provider/label_repositories_provider.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';
import 'package:paperless_mobile/features/inbox/view/pages/inbox_page.dart';
import 'package:paperless_mobile/features/login/bloc/authentication_cubit.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/view/settings_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InfoDrawer extends StatefulWidget {
  final VoidCallback? afterInboxClosed;

  const InfoDrawer({Key? key, this.afterInboxClosed}) : super(key: key);

  @override
  State<InfoDrawer> createState() => _InfoDrawerState();
}

enum NavigationDestinations {
  inbox,
  settings,
  reportBug,
  about,
  logout;
}

class _InfoDrawerState extends State<InfoDrawer> {
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final listtTileShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32),
    );
    // return NavigationDrawer(
    //   selectedIndex: -1,
    //   children: [
    //     Text(
    //       "",
    //       style: Theme.of(context).textTheme.titleSmall,
    //     ).padded(16),
    //     NavigationDrawerDestination(
    //       icon: const Icon(Icons.inbox),
    //       label: Text(S.of(context).bottomNavInboxPageLabel),
    //     ),
    //     NavigationDrawerDestination(
    //       icon: const Icon(Icons.settings),
    //       label: Text(S.of(context).appDrawerSettingsLabel),
    //     ),
    //     const Divider(
    //       indent: 16,
    //     ),
    //     NavigationDrawerDestination(
    //       icon: const Icon(Icons.bug_report),
    //       label: Text(S.of(context).appDrawerReportBugLabel),
    //     ),
    //     NavigationDrawerDestination(
    //       icon: const Icon(Icons.info_outline),
    //       label: Text(S.of(context).appDrawerAboutLabel),
    //     ),
    //   ],
    //   onDestinationSelected: (idx) {
    //     final val = NavigationDestinations.values[idx - 1];
    //     switch (val) {
    //       case NavigationDestinations.inbox:
    //         _onOpenInbox();
    //         break;
    //       case NavigationDestinations.settings:
    //         _onOpenSettings();
    //         break;
    //       case NavigationDestinations.reportBug:
    //         launchUrlString(
    //           'https://github.com/astubenbord/paperless-mobile/issues/new',
    //         );
    //         break;
    //       case NavigationDestinations.about:
    //         _onShowAboutDialog();
    //         break;
    //       case NavigationDestinations.logout:
    //         _onLogout();
    //         break;
    //     }
    //   },
    // );
    return SafeArea(
      top: true,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16.0),
          bottomRight: Radius.circular(16.0),
        ),
        child: Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16.0),
              bottomRight: Radius.circular(16.0),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: ListTileThemeData(
                tileColor: Colors.transparent,
              ),
            ),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ).paddedOnly(right: 8.0),
                          Text(
                            S.of(context).appTitleText,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
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
                                    S
                                            .of(context)
                                            .appDrawerHeaderLoggedInAsText +
                                        (info.username ?? '?'),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        state.information!.host ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        maxLines: 1,
                                      ),
                                      Text(
                                        '${S.of(context).serverInformationPaperlessVersionText} ${info.version} (API v${info.apiVersion})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
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
                ...[
                  ListTile(
                    title: Text(S.of(context).bottomNavInboxPageLabel),
                    leading: const Icon(Icons.inbox),
                    onTap: () => _onOpenInbox(),
                    shape: listtTileShape,
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    shape: listtTileShape,
                    title: Text(
                      S.of(context).appDrawerSettingsLabel,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<ApplicationSettingsCubit>(),
                          child: const SettingsPage(),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: Text(S.of(context).appDrawerReportBugLabel),
                    onTap: () {
                      launchUrlString(
                          'https://github.com/astubenbord/paperless-mobile/issues/new');
                    },
                    shape: listtTileShape,
                  ),
                  ListTile(
                    title: Text(S.of(context).appDrawerAboutLabel),
                    leading: Icon(Icons.info_outline_rounded),
                    onTap: _onShowAboutDialog,
                    shape: listtTileShape,
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(S.of(context).appDrawerLogoutLabel),
                    shape: listtTileShape,
                    onTap: () {
                      _onLogout();
                    },
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onLogout() {
    try {
      context.read<AuthenticationCubit>().logout();
      context.read<LocalVault>().clear();
      context.read<ApplicationSettingsCubit>().clear();
      context.read<LabelRepository<Tag, TagRepositoryState>>().clear();
      context
          .read<LabelRepository<Correspondent, CorrespondentRepositoryState>>()
          .clear();
      context
          .read<LabelRepository<DocumentType, DocumentTypeRepositoryState>>()
          .clear();
      context
          .read<LabelRepository<StoragePath, StoragePathRepositoryState>>()
          .clear();
      context.read<SavedViewRepository>().clear();
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }

  Future<void> _onOpenInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabelRepositoriesProvider(
          child: BlocProvider(
            create: (context) => InboxCubit(
              context.read<LabelRepository<Tag, TagRepositoryState>>(),
              context.read<PaperlessDocumentsApi>(),
            )..initializeInbox(),
            child: const InboxPage(),
          ),
        ),
      ),
    );
    widget.afterInboxClosed?.call();
  }

  void _onOpenSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ApplicationSettingsCubit>(),
          child: const SettingsPage(),
        ),
      ),
    );
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

  Future<void> _onShowAboutDialog() async {
    final snapshot = await _packageInfo;
    showAboutDialog(
      context: context,
      applicationIcon: const ImageIcon(
        AssetImage('assets/logos/paperless_logo_green.png'),
      ),
      applicationName: 'Paperless Mobile',
      applicationVersion: snapshot.version + '+' + snapshot.buildNumber,
      children: [
        Text('${S.of(context).aboutDialogDevelopedByText} Anton Stubenbord'),
        Link(
          uri: Uri.parse('https://github.com/astubenbord/paperless-mobile'),
          builder: (context, followLink) => GestureDetector(
            onTap: followLink,
            child: Text(
              'https://github.com/astubenbord/paperless-mobile',
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
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
    );
  }
}
