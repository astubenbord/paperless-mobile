import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/labels/model/label.model.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_item.dart';

class LabelTabView<T extends Label> extends StatelessWidget {
  final LabelCubit<T> cubit;
  final DocumentFilter Function(Label) filterBuilder;
  final void Function(T) onOpenEditPage;

  /// Displayed as the subtitle of the [ListTile]
  final Widget Function(T)? contentBuilder;

  /// Displayed as the leading widget of the [ListTile]
  final Widget Function(T)? leadingBuilder;

  const LabelTabView({
    super.key,
    required this.cubit,
    required this.filterBuilder,
    this.contentBuilder,
    this.leadingBuilder,
    required this.onOpenEditPage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Cubit<Map<int, T>>, Map<int, T>>(
      bloc: cubit,
      builder: (context, state) {
        final labels = state.values.toList()..sort();
        return RefreshIndicator(
          onRefresh: cubit.initialize,
          child: ListView(
            children: labels
                .map((l) => LabelItem<T>(
                      name: l.name,
                      content: contentBuilder?.call(l) ?? Text(l.match ?? '-'),
                      onOpenEditPage: onOpenEditPage,
                      filterBuilder: filterBuilder,
                      leading: leadingBuilder?.call(l),
                      label: l,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
