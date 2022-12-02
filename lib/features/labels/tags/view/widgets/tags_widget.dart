import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tag_widget.dart';

class TagsWidget extends StatefulWidget {
  final Iterable<int> tagIds;
  final bool isMultiLine;
  final VoidCallback? afterTagTapped;
  final void Function(int tagId) onTagSelected;
  final bool isClickable;
  final bool Function(int id) isSelectedPredicate;

  const TagsWidget({
    Key? key,
    required this.tagIds,
    this.afterTagTapped,
    this.isMultiLine = true,
    this.isClickable = true,
    required this.isSelectedPredicate,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  State<TagsWidget> createState() => _TagsWidgetState();
}

class _TagsWidgetState extends State<TagsWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagCubit, LabelState<Tag>>(
      builder: (context, state) {
        final children = widget.tagIds
            .where((id) => state.labels.containsKey(id))
            .map(
              (id) => TagWidget(
                tag: state.getLabel(id)!,
                afterTagTapped: widget.afterTagTapped,
                isClickable: widget.isClickable,
                isSelected: widget.isSelectedPredicate(id),
                onSelected: () => widget.onTagSelected(id),
              ),
            )
            .toList();
        if (widget.isMultiLine) {
          return Wrap(
            runAlignment: WrapAlignment.start,
            children: children,
            runSpacing: 8,
            spacing: 4,
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: children,
            ),
          );
        }
      },
    );
  }
}
