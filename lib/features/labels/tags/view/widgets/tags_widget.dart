import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tag_widget.dart';

class TagsWidget extends StatefulWidget {
  final Iterable<int> tagIds;
  final bool isMultiLine;
  final void Function()? afterTagTapped;
  final bool isClickable;

  const TagsWidget({
    Key? key,
    required this.tagIds,
    this.afterTagTapped,
    this.isMultiLine = true,
    this.isClickable = true,
  }) : super(key: key);

  @override
  State<TagsWidget> createState() => _TagsWidgetState();
}

class _TagsWidgetState extends State<TagsWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagCubit, Map<int, Tag>>(
      builder: (context, state) {
        final children = widget.tagIds
            .where((id) => state.containsKey(id))
            .map(
              (id) => TagWidget(
                tag: state[id]!,
                afterTagTapped: widget.afterTagTapped,
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
