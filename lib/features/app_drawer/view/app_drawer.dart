import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/generated/assets.gen.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/settings_route.dart';
import 'package:paperless_mobile/routing/routes/upload_queue_route.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final uiSettings = context.uiSettings$;
    final username = uiSettings.user.username;
    final appVersion = packageInfo.version;
    final serverUrl = context.loggedInUser$.serverUrl.replaceAll(
      RegExp(r'https?://'),
      '',
    );
    final topInset = MediaQuery.paddingOf(context).top;
    return SafeArea(
      top: false,
      child: Drawer(
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  const $AssetsLogosGen().paperlessLogoGreenSvg.svg(
                    width: 32,
                    height: 32,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Paperless Mobile",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        appVersion,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ).paddedLTRB(8, 8, 8, 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(128),
                      ),
                      Text(
                        S.of(context)!.loggedInAs(username),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(128),
                            ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dns,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(128),
                      ),
                      Text(
                        serverUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(128),
                            ),
                      ),
                    ],
                  ),
                ],
              ).paddedSymmetrically(horizontal: 16),
              const Divider(),
              ListTile(
                dense: true,
                title: Text(S.of(context)!.aboutThisApp),
                leading: const Icon(Icons.info_outline),
                onTap: () => _showAboutDialog(context),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.favorite_outline),
                title: Text(S.of(context)!.donate),
                onTap: () {
                  showDialog(
                    useRootNavigator: false,
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(Icons.favorite),
                      title: Text(S.of(context)!.donate),
                      content: Text(S.of(context)!.donationDialogContent),
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                      actions: [
                        const Text("~ Anton"),
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: Text(S.of(context)!.gotIt),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.bug_report_outlined),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.of(context)!.reportABug),
                    const Icon(Icons.open_in_new, size: 16),
                  ],
                ),
                onTap: () {
                  launchUrlString(
                    'https://github.com/astubenbord/paperless-mobile/issues/new?assignees=astubenbord&labels=bug%2Ctriage&projects=&template=bug-report.yml&title=%5BBug%5D%3A+',
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Assets.images.githubMark.svg(
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                  height: 24,
                  width: 24,
                ),
                title: Text(S.of(context)!.sourceCode),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () {
                  launchUrlString(
                    "https://github.com/astubenbord/paperless-mobile",
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              Consumer<ConsumptionChangeNotifier>(
                builder: (context, value, child) {
                  final files = value.pendingFiles;
                  final child = ListTile(
                    dense: true,
                    leading: const Icon(Icons.drive_folder_upload_outlined),
                    title: Text(S.of(context)!.pendingFiles),
                    onTap: () {
                      UploadQueueRoute().push(context);
                    },
                    trailing: Text(
                      '${files.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                  if (files.isEmpty) {
                    return child;
                  }
                  return child
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                        autoPlay: !MediaQuery.disableAnimationsOf(context),
                      )
                      .fade(duration: 1.seconds, begin: 1, end: 0.3);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.settings_outlined),
                title: Text(S.of(context)!.settings),
                onTap: () => SettingsRoute().push(context),
              ),
              const Divider(),
              if (uiSettings.canViewSavedViews) ...[
                Text(
                  S.of(context)!.views,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.labelLarge,
                ).padded(16),
                _buildSavedViews(context, uiSettings),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedViews(BuildContext context, UiSettingsView uiSettings) {
    return QueryBuilder(
      query: context.read<SavedViewRepository>().getAllQuery(),
      builder: (context, state) {
        if (state.isInitial) {
          return const SizedBox.shrink();
        }
        if (state.isLoadingInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isError) {
          return Text(S.of(context)!.couldNotLoadSavedViews);
        }
        final sidebarViews =
            state.data?.where((element) => element.showInSidebar).toList() ??
            [];

        if (state.data?.isEmpty ?? true) {
          return Text(
            S.of(context)!.youDidNotSaveAnyViewsYet,
            style: Theme.of(context).textTheme.bodySmall,
          ).paddedOnly(left: 16, right: 16);
        }

        if (sidebarViews.isEmpty) {
          return Text(
            S.of(context)!.noViewsMarkedInSidebar,
            style: Theme.of(context).textTheme.bodySmall,
          ).paddedOnly(left: 16, right: 16);
        }

        return Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              final view = sidebarViews[index];
              return ListTile(
                enabled: uiSettings.canViewDocuments,
                title: Text(view.name),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Scaffold.of(context).closeDrawer();
                  context.localStore.updateCurrentDocumentFilter(
                    (_) => view.toDocumentFilter(),
                  );
                  DocumentsRoute().go(context);
                },
              );
            },
            itemCount: sidebarViews.length,
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showAboutDialog(
      context: context,
      applicationIcon: const ImageIcon(
        AssetImage('assets/logos/paperless_logo_green.png'),
      ),
      applicationName: 'Paperless Mobile',
      applicationVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      children: [
        Text(S.of(context)!.developedBy('Anton Stubenbord')),
        const SizedBox(height: 16),
        Text(S.of(context)!.sourceCode, style: theme.textTheme.titleMedium),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            children: [
              TextSpan(text: S.of(context)!.findTheSourceCodeOn),
              TextSpan(
                text: ' GitHub',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrlString(
                      'https://github.com/astubenbord/paperless-mobile',
                      mode: LaunchMode.externalApplication,
                    );
                  },
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

//Wrap(
//   children: [
//     const Text('Onboarding images by '),
//     GestureDetector(
//       onTap: followLink,
//       child: RichText(

//         'pch.vector',
//         style: TextStyle(color: Colors.blue),
//       ),
//     ),
//     const Text(' on Freepik.')
//   ],
// )
