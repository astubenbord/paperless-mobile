import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/features/landing/view/widgets/expansion_card.dart';
import 'package:paperless_mobile/features/landing/view/widgets/mime_types_pie_chart.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/features/saved_view/view/saved_view_preview.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/inbox_route.dart';
import 'package:paperless_mobile/routing/routes/saved_views_route.dart';
import 'package:paperless_mobile/routing/routes/scanner_route.dart';
import 'package:paperless_mobile/routing/routes/changelog_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _searchBarHandle = SliverOverlapAbsorberHandle();

  Future<bool> get _shouldShowChangelog async {
    try {
      final sp = await SharedPreferences.getInstance();
      final currentBuild = packageInfo.buildNumber;
      final existingVersions = sp.getStringList('changelogSeenForBuilds') ?? [];
      if (existingVersions.contains(currentBuild)) {
        return false;
      } else {
        existingVersions.add(currentBuild);
        await sp.setStringList('changelogSeenForBuilds', existingVersions);
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await _shouldShowChangelog && mounted) {
        ChangelogRoute().push(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LocalUserAccount>().paperlessUser;
    return SafeArea(
      child: Scaffold(
        drawer: const AppDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: _searchBarHandle,
              sliver: SliverSearchBar(
                titleText: S.of(context)!.documents,
              ),
            ),
          ],
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context)!.welcomeUser(
                            currentUser.fullName ?? currentUser.username,
                          ),
                      textAlign: TextAlign.left,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ).padded(24),
              ),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              if (currentUser.canViewInbox)
                SliverToBoxAdapter(child: _buildInboxPreview(context)),
              SliverToBoxAdapter(
                child: _buildStatisticsCard(context),
              ),
              if (currentUser.canViewSavedViews) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(
                          Icons.saved_search,
                          color: Theme.of(context).colorScheme.primary,
                        ).paddedOnly(right: 8),
                        Text(
                          S.of(context)!.views,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<SavedViewCubit, SavedViewState>(
                  builder: (context, state) {
                    return state.maybeWhen(
                      loaded: (savedViews) {
                        final dashboardViews = savedViews.values
                            .where((element) => element.showOnDashboard)
                            .toList();
                        if (dashboardViews.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.of(context)!.youDidNotSaveAnyViewsYet,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ).padded(),
                                TextButton.icon(
                                  onPressed: () {
                                    const CreateSavedViewRoute(
                                      showOnDashboard: true,
                                    ).push(context);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: Text(S.of(context)!.newView),
                                )
                              ],
                            ).paddedOnly(left: 16),
                          );
                        }
                        return SliverList.builder(
                          itemBuilder: (context, index) {
                            return SavedViewPreview(
                              savedView: dashboardViews.elementAt(index),
                              expanded: index == 0,
                            );
                          },
                          itemCount: dashboardViews.length,
                        );
                      },
                      orElse: () => const SliverToBoxAdapter(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionCard(
              context,
              icon: Icons.document_scanner,
              label: S.of(context)!.scanner,
              color: colorScheme.primaryContainer,
              onTap: () => const ScannerRoute().go(context),
            ),
            const SizedBox(width: 8),
            _buildQuickActionCard(
              context,
              icon: Icons.inbox,
              label: S.of(context)!.inbox,
              color: colorScheme.primaryContainer,
              onTap: () => InboxRoute().go(context),
            ),
            const SizedBox(width: 8),
            _buildQuickActionCard(
              context,
              icon: Icons.description,
              label: S.of(context)!.documents,
              color: colorScheme.primaryContainer,
              onTap: () => DocumentsRoute().go(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInboxPreview(BuildContext context) {
    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        final documents = state.documents;
        if (!state.hasLoaded) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inbox,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context)!.inbox,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (documents.isNotEmpty)
                    TextButton(
                      onPressed: () => InboxRoute().go(context),
                      child: Text(S.of(context)!.showAll),
                    ),
                ],
              ),
              if (documents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    S.of(context)!.youDoNotHaveUnseenDocuments,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                ...documents.take(5).map(
                      (doc) => _buildInboxDocumentTile(context, doc),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInboxDocumentTile(BuildContext context, DocumentModel doc) {
    final dateStr = DateFormat.yMMMd().format(doc.created);
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          doc.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          dateStr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          DocumentDetailsRoute(
            id: doc.id,
            isLabelClickable: true,
          ).push(context);
        },
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    final currentUser = context.read<LocalUserAccount>().paperlessUser;
    return ExpansionCard(
      initiallyExpanded: false,
      title: Text(
        S.of(context)!.statistics,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: FutureBuilder<PaperlessServerStatisticsModel>(
        future: context.read<PaperlessServerStatsApi>().getServerStatistics(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                S.of(context)!.anUnknownErrorOccurred,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ).paddedOnly(top: 8, bottom: 24);
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            ).paddedOnly(top: 8, bottom: 24);
          }
          final stats = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                elevation: 0,
                child: ListTile(
                  shape: Theme.of(context).cardTheme.shape,
                  titleTextStyle: Theme.of(context).textTheme.labelLarge,
                  leading: Icon(Icons.inbox, color: Theme.of(context).colorScheme.primary),
                  title: Text(S.of(context)!.documentsInInbox),
                  onTap: currentUser.canViewInbox
                      ? () => InboxRoute().go(context)
                      : null,
                  trailing: Text(
                    stats.documentsInInbox.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                elevation: 0,
                child: ListTile(
                  shape: Theme.of(context).cardTheme.shape,
                  titleTextStyle: Theme.of(context).textTheme.labelLarge,
                  leading: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                  title: Text(S.of(context)!.totalDocuments),
                  onTap: currentUser.canViewDocuments
                      ? () {
                          DocumentsRoute().go(context);
                        }
                      : null,
                  trailing: Text(
                    stats.documentsTotal.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                elevation: 0,
                child: ListTile(
                  shape: Theme.of(context).cardTheme.shape,
                  titleTextStyle: Theme.of(context).textTheme.labelLarge,
                  leading: Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
                  title: Text(S.of(context)!.totalCharacters),
                  trailing: Text(
                    (stats.totalChars ?? 0).toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (stats.fileTypeCounts.isNotEmpty)
                AspectRatio(
                  aspectRatio: 1.3,
                  child: SizedBox(
                    width: 300,
                    child: MimeTypesPieChart(statistics: stats),
                  ),
                ),
            ],
          ).padded(16);
        },
      ),
    );
  }
}
