import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/util.dart';

class TagWidget extends StatelessWidget {
  final Tag tag;
  final void Function()? afterTagTapped;
  final bool isClickable;
  const TagWidget({
    super.key,
    required this.tag,
    required this.afterTagTapped,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          final isIdsQuery = state.filter.tags is IdsTagsQuery;
          return FilterChip(
            selected: isIdsQuery
                ? (state.filter.tags as IdsTagsQuery)
                    .includedIds
                    .contains(tag.id)
                : false,
            selectedColor: tag.color,
            onSelected: (_) => _addTagToFilter(context),
            visualDensity: const VisualDensity(vertical: -2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text(
              tag.name,
              style: TextStyle(color: tag.textColor),
            ),
            checkmarkColor: tag.textColor,
            backgroundColor: tag.color,
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  void _addTagToFilter(BuildContext context) {
    if (!isClickable) {
      return;
    }
    final cubit = BlocProvider.of<DocumentsCubit>(context);
    try {
      final tagsQuery = cubit.state.filter.tags is IdsTagsQuery
          ? cubit.state.filter.tags as IdsTagsQuery
          : const IdsTagsQuery();
      if (tagsQuery.includedIds.contains(tag.id)) {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
            tags: tagsQuery.withIdsRemoved([tag.id!]),
          ),
        );
      } else {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
            tags: tagsQuery.withIdQueriesAdded([IncludeTagIdQuery(tag.id!)]),
          ),
        );
      }
      if (afterTagTapped != null) {
        afterTagTapped!();
      }
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
