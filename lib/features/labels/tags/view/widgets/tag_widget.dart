import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';

class TagWidget extends StatelessWidget {
  final Tag tag;
  final void Function()? afterTagTapped;
  const TagWidget({super.key, required this.tag, required this.afterTagTapped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          return FilterChip(
            selected: state.filter.tags.ids.contains(tag.id),
            selectedColor: tag.color,
            onSelected: (_) => _addTagToFilter(context),
            visualDensity: const VisualDensity(vertical: -2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text(
              tag.name,
              style: TextStyle(color: tag.textColor),
            ),
            backgroundColor: tag.color,
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  void _addTagToFilter(BuildContext context) {
    final cubit = BlocProvider.of<DocumentsCubit>(context);
    if (cubit.state.filter.tags.ids.contains(tag.id)) {
      cubit.updateFilter(
        filter: cubit.state.filter.copyWith(
          tags: TagsQuery.fromIds(cubit.state.filter.tags.ids.where((id) => id != tag.id).toList()),
        ),
      );
    } else {
      cubit.updateFilter(
        filter: cubit.state.filter
            .copyWith(tags: TagsQuery.fromIds([...cubit.state.filter.tags.ids, tag.id!])),
      );
    }
    if (afterTagTapped != null) {
      afterTagTapped!();
    }
  }
}
