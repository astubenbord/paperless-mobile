import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/core/widgets/offline_widget.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/model/label_state.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_item.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class LabelTabView<T extends Label> extends StatelessWidget {
  final LabelCubit<T> cubit;
  final DocumentFilter Function(Label) filterBuilder;
  final void Function(T) onOpenEditPage;
  final void Function() onOpenAddNewPage;

  /// Displayed as the subtitle of the [ListTile]
  final Widget Function(T)? contentBuilder;

  /// Displayed as the leading widget of the [ListTile]
  final Widget Function(T)? leadingBuilder;

  /// Shown on empty State
  final String emptyStateDescription;
  final String emptyStateActionButtonLabel;

  const LabelTabView({
    super.key,
    required this.cubit,
    required this.filterBuilder,
    this.contentBuilder,
    this.leadingBuilder,
    required this.onOpenEditPage,
    required this.emptyStateDescription,
    required this.onOpenAddNewPage,
    required this.emptyStateActionButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state == ConnectivityState.notConnected) {
          return const OfflineWidget();
        }
        return RefreshIndicator(
          onRefresh: cubit.initialize,
          child: BlocBuilder<Cubit<LabelState<T>>, LabelState<T>>(
            bloc: cubit,
            builder: (context, state) {
              final labels = state.labels.values.toList()..sort();
              if (labels.isEmpty) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        emptyStateDescription,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: onOpenAddNewPage,
                        child: Text(emptyStateActionButtonLabel),
                      )
                    ].padded(),
                  ),
                );
              }
              return ListView(
                children: labels
                    .map((l) => LabelItem<T>(
                          name: l.name,
                          content:
                              contentBuilder?.call(l) ?? Text(l.match ?? '-'),
                          onOpenEditPage: onOpenEditPage,
                          filterBuilder: filterBuilder,
                          leading: leadingBuilder?.call(l),
                          label: l,
                        ))
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }
}
