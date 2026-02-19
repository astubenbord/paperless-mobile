import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_cubit.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/generated/assets.gen.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/saved_views_route.dart';
import 'package:paperless_mobile/routing/routes/settings_route.dart';
import 'package:paperless_mobile/routing/routes/upload_queue_route.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/features/ai_chat/cubit/ai_chat_cubit.dart';
import 'package:paperless_mobile/features/ai_chat/view/ai_chat_page.dart';
import 'package:paperless_mobile/features/ai_chat/view/ai_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentAccount = context.watch<LocalUserAccount>();
    final username = currentAccount.paperlessUser.username;
    final serverUrl =
        currentAccount.serverUrl.replaceAll(RegExp(r'https?://'), '');
    return SafeArea(
      child: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const $AssetsLogosGen()
                    .paperlessLogoGreenSvg
                    .svg(width: 32, height: 32),
                SizedBox(width: 8),
                Text(
                  "Paperless Mobile",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ).paddedLTRB(8, 8, 8, 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context)!.loggedInAs(username),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(128),
                      ),
                ),
                Text(
                  serverUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(128),
                      ),
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
                  context: context,
                  builder: (context) => AlertDialog(
                    icon: const Icon(Icons.favorite),
                    title: Text(S.of(context)!.donate),
                    content: Text(
                      S.of(context)!.donationDialogContent,
                    ),
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
                  const Icon(
                    Icons.open_in_new,
                    size: 16,
                  )
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
              trailing: const Icon(
                Icons.open_in_new,
                size: 16,
              ),
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
                  title: const Text("Pending Files"),
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
            _buildAiDrawerItems(context),
            ListTile(
              dense: true,
              leading: const Icon(Icons.settings_outlined),
              title: Text(
                S.of(context)!.settings,
              ),
              onTap: () => SettingsRoute().push(context),
            ),
            const Divider(),
            Text(
              S.of(context)!.views,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.labelLarge,
            ).padded(16),
            _buildSavedViews(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedViews() {
    return BlocBuilder<SavedViewCubit, SavedViewState>(
        builder: (context, state) {
      return state.when(
        initial: () => const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (savedViews) {
          final sidebarViews = savedViews.values
              .where((element) => element.showInSidebar)
              .toList();
          if (sidebarViews.isEmpty) {
            return Column(
              children: [
                Text(
                  S.of(context)!.youDidNotSaveAnyViewsYet,
                  style: Theme.of(context).textTheme.bodySmall,
                ).paddedOnly(
                  left: 16,
                  right: 16,
                ),
                TextButton.icon(
                  onPressed: () {
                    Scaffold.of(context).closeDrawer();
                    const CreateSavedViewRoute(showInSidebar: true)
                        .push(context);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(S.of(context)!.newView),
                ),
              ],
            );
          }
          return Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                final view = sidebarViews[index];
                return ListTile(
                  title: Text(view.name),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    context
                        .read<DocumentsCubit>()
                        .updateFilter(filter: view.toDocumentFilter());
                    DocumentsRoute().go(context);
                  },
                );
              },
              itemCount: sidebarViews.length,
            ),
          );
        },
        error: () => Text(S.of(context)!.couldNotLoadSavedViews),
      );
    });
  }

  Widget _buildAiDrawerItems(BuildContext context) {
    return ValueListenableBuilder<Box<GlobalSettings>>(
      valueListenable:
          Hive.box<GlobalSettings>(HiveBoxes.globalSettings).listenable(),
      builder: (context, box, _) {
        final settings = box.getValue()!;
        final isConfigured = settings.aiServerUrl.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConfigured)
              ListTile(
                dense: true,
                leading: const Icon(Icons.auto_awesome),
                title: Text(S.of(context)!.aiChat),
                onTap: () {
                  Scaffold.of(context).closeDrawer();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => AiChatCubit(
                          serverUrl: settings.aiServerUrl,
                          apiKey: settings.aiApiKey,
                        ),
                        child: const AiChatPage(),
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(S.of(context)!.aiSettings),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AiSettingsPage(),
                  ),
                );
              },
            ),
          ],
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
        Text(
          "Source Code",
          style: theme.textTheme.titleMedium,
        ),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurface),
            children: [
              TextSpan(
                text: S.of(context)!.findTheSourceCodeOn,
              ),
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
        const SizedBox(height: 16),
        Text(
          'Credits',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: colorScheme.onSurface),
        ),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurface),
            children: [
              const TextSpan(
                text: 'Onboarding images by ',
              ),
              TextSpan(
                text: 'pch.vector',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrlString(
                        'https://www.freepik.com/free-vector/business-team-working-cogwheel-mechanism-together_8270974.htm#query=setting&position=4&from_view=author');
                  },
              ),
              const TextSpan(
                text: ' on Freepik.',
              ),
            ],
          ),
        ),
      ],
    );
  }

}
