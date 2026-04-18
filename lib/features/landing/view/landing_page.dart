import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/repository/server_statistics_repository.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/document_search/view/sliver_search_bar.dart';
import 'package:paperless_mobile/features/landing/view/widgets/expansion_card.dart';
import 'package:paperless_mobile/features/landing/view/widgets/mime_types_pie_chart.dart';
import 'package:paperless_mobile/features/saved_view_details/view/saved_view_preview.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';
import 'package:paperless_mobile/routing/routes/inbox_route.dart';
import 'package:paperless_mobile/routing/routes/saved_views_route.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _searchBarHandle = SliverOverlapAbsorberHandle();

  @override
  void initState() {
    super.initState();
    context.read<ServerStatisticsRepository>().serverStatisticsQuery.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: const AppDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: _searchBarHandle,
              sliver: SliverSearchBar(titleText: S.of(context)!.documents),
            ),
          ],
          body: RefreshIndicator(
            onRefresh: () {
              return context
                  .read<ServerStatisticsRepository>()
                  .serverStatisticsQuery
                  .refetch();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Text(
                    S
                        .of(context)!
                        .welcomeUser(context.loggedInUser$.displayName),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(fontSize: 28),
                  ).padded(24),
                ),
                SliverToBoxAdapter(child: _buildStatisticsCard(context)),
                if (context.uiSettings$.canViewSavedViews) ...[
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
                  QueryBuilder(
                    query: context.read<SavedViewRepository>().getAllQuery(),
                    builder: (context, state) {
                      if (state.isLoadingInitial) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (state.isError) {
                        return SliverToBoxAdapter(
                          child: Text(
                            S.of(context)!.couldNotLoadSavedViews,
                          ).padded(16),
                        );
                      }
                      final savedViews = state.data ?? [];
                      final dashboardViews = savedViews
                          .where((element) => element.showOnDashboard)
                          .toList();
                      if (dashboardViews.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context)!.youHaveNoViewsOnYourDashboardYet,
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
                              ),
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
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    return ExpansionCard(
      initiallyExpanded: false,
      title: Text(
        S.of(context)!.statistics,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: QueryBuilder(
        query: context.read<ServerStatisticsRepository>().serverStatisticsQuery,
        builder: (context, state) {
          if (state.isLoadingInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            ).paddedOnly(top: 8, bottom: 24);
          }
          if (state.isError) {
            return Center(
              child: Text(S.of(context)!.anUnknownErrorOccurred),
            ).padded(16);
          }
          final stats = state.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  shape: Theme.of(context).cardTheme.shape,
                  titleTextStyle: Theme.of(context).textTheme.labelLarge,
                  title: Text(S.of(context)!.documentsInInbox),
                  onTap: context.uiSettings$.canViewInbox
                      ? () => InboxRoute().go(context)
                      : null,
                  trailing: Text(
                    stats.documentsInbox.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  shape: Theme.of(context).cardTheme.shape,
                  titleTextStyle: Theme.of(context).textTheme.labelLarge,
                  title: Text(S.of(context)!.totalDocuments),
                  onTap: context.uiSettings$.canViewDocuments
                      ? () {
                          DocumentsRoute().go(context);
                        }
                      : null,
                  trailing: Text(
                    stats.documentsTotal.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  shape: Theme.of(context).cardTheme.shape,
                  titleTextStyle: Theme.of(context).textTheme.labelLarge,
                  title: Text(S.of(context)!.totalCharacters),
                  trailing: Text(
                    (stats.characterCount ?? 0).toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              if (stats.documentFileTypeCounts.isNotEmpty)
                MimeTypesPieChart(statistics: stats),
            ],
          ).padded(16);
        },
      ),
    );
  }
}
