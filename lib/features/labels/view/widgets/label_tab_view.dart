import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/translation/matching_algorithm_localization_mapper.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_item.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class LabelTabView<T extends Label> extends StatelessWidget {
  final Query<List<T>> query;
  final DocumentFilter Function(Label) filterBuilder;
  final void Function(T) onEdit;
  final bool canEdit;
  final void Function() onAddNew;
  final bool canAddNew;
  final bool canView;

  /// Displayed as the subtitle of the [ListTile]
  final Widget Function(T)? contentBuilder;

  /// Displayed as the leading widget of the [ListTile]
  final Widget Function(T)? leadingBuilder;

  /// Shown on empty State
  final String emptyStateDescription;
  final String emptyStateActionButtonLabel;

  const LabelTabView({
    super.key,
    required this.filterBuilder,
    this.contentBuilder,
    this.leadingBuilder,
    required this.onEdit,
    required this.emptyStateDescription,
    required this.onAddNew,
    required this.emptyStateActionButtonLabel,
    required this.query,
    required this.canEdit,
    required this.canAddNew,
    required this.canView,
  });

  @override
  Widget build(BuildContext context) {
    if (!canView) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(
            S.of(context)!.unauthorizedErrorMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, connectivityState) {
        if (!connectivityState.isConnected) {
          return const SliverFillRemaining(child: OfflineWidget());
        }
        return QueryBuilder(
          query: query,
          builder: (context, state) {
            if (state is QueryLoading && state.data == null) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.isError) {
              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    S.of(context)!.couldNotLoadCorrespondents,
                    textAlign: TextAlign.center,
                  ).padded(),
                ),
              );
            }
            final labels = state.data ?? [];
            final sortedLabels = labels.toList()..sort();
            if (labels.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emptyStateDescription, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: canAddNew ? onAddNew : null,
                        child: Text(emptyStateActionButtonLabel),
                      ),
                    ].padded(),
                  ),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final l = sortedLabels.elementAt(index);
                return LabelItem<T>(
                  name: l.name,
                  content:
                      contentBuilder?.call(l) ??
                      Text(
                        translateMatchingAlgorithmName(
                              context,
                              l.matchingAlgorithm,
                            ) +
                            (l.match.isNotEmpty ? ": ${l.match}" : ""),
                        maxLines: 2,
                      ),
                  onOpenEditPage: canEdit ? onEdit : null,
                  filterBuilder: filterBuilder,
                  leading: leadingBuilder?.call(l),
                  label: l,
                );
              }, childCount: labels.length),
            );
          },
        );
      },
    );
  }
}
