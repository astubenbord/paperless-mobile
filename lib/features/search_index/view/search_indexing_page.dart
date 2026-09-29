import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/store/bloc/current_user_app_state_builder.dart';
import 'package:paperless_mobile/features/search_index/cubit/search_index_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SearchIndexingPage extends StatelessWidget {
  const SearchIndexingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchIndexCubit>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context)!.indexing)),
      body: CurrentUserAppDataBuilder(
        builder: (context, userData) =>
            BlocBuilder<SearchIndexCubit, SearchIndexState>(
              builder: (context, state) {
                final lastSync = userData.searchIndexLastSync;
                return ListView(
                  children: [
                    SwitchListTile(
                      value: userData.searchIndexingEnabled,
                      title: Text(S.of(context)!.deviceSearchIndexing),
                      subtitle: Text(
                        S.of(context)!.deviceSearchIndexingDescription,
                      ),
                      onChanged: cubit.setEnabled,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card.filled(
                        child: ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: Text(S.of(context)!.searchIndexPrivacyWarning),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: state.syncing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: (state.total ?? 0) > 0
                                      ? state.processed / state.total!
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${state.processed} / ${state.total ?? '?'}',
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.indexedCount != null)
                                  Text(
                                    S
                                        .of(context)!
                                        .indexedDocumentsCount(
                                          state.indexedCount!,
                                        ),
                                  ),
                                if (lastSync != null)
                                  Text(
                                    S
                                        .of(context)!
                                        .lastSync(
                                          context.displayDateFormat
                                              .add_Hm()
                                              .format(lastSync.toLocal()),
                                        ),
                                  ),
                                if (state.lastError != null)
                                  Text(
                                    S.of(context)!.lastError(state.lastError!),
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed:
                                userData.searchIndexingEnabled && !state.syncing
                                ? cubit.sync
                                : null,
                            child: Text(S.of(context)!.syncNow),
                          ),
                          OutlinedButton(
                            onPressed: state.syncing ? null : cubit.clearIndex,
                            child: Text(S.of(context)!.clearIndex),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        S.of(context)!.samsungFinderSearchHint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}
