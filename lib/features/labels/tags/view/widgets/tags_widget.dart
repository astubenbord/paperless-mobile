import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tag_widget.dart';

class TagsWidget extends StatelessWidget {
  final List<Tag> tags;
  final void Function(int tagId)? onTagSelected;
  final bool isClickable;
  final bool showShortNames;
  final bool dense;
  final int? maxTags;

  const TagsWidget({
    super.key,
    required this.tags,
    this.onTagSelected,
    this.isClickable = true,
    this.showShortNames = false,
    this.dense = true,
    this.maxTags,
  });

  List<Widget> get _children {
    final displayTags = (maxTags != null && tags.length > maxTags!)
        ? tags.sublist(0, maxTags!)
        : tags;
    return [
      for (var tag in displayTags)
        TagWidget(
          tag: tag,
          isClickable: isClickable,
          onSelected: () => onTagSelected?.call(tag.id!),
          showShortName: showShortNames,
          dense: dense,
        ),
      if (maxTags != null && tags.length > maxTags!)
        _OverflowChip(count: tags.length - maxTags!, dense: dense),
    ];
  }

  const factory TagsWidget.multiLine({
    Key? key,
    required List<Tag> tags,
    required void Function(int tagId)? onTagSelected,
    required bool isClickable,
    required bool showShortNames,
    required bool dense,
    int? maxTags,
  }) = _MultiLineTagsWidget;

  const factory TagsWidget.sliver({
    Key? key,
    required List<Tag> tags,
    void Function(int tagId)? onTagSelected,
    bool isClickable,
    bool showShortNames,
    bool dense,
    int? maxTags,
  }) = _SliverTagsWidget;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: _children),
    );
  }
}

class _OverflowChip extends StatelessWidget {
  final int count;
  final bool dense;

  const _OverflowChip({required this.count, required this.dense});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MultiLineTagsWidget extends TagsWidget {
  const _MultiLineTagsWidget({
    super.key,
    required super.tags,
    super.onTagSelected,
    super.isClickable,
    super.showShortNames,
    super.dense,
    super.maxTags,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runAlignment: WrapAlignment.start,
      runSpacing: 4,
      spacing: 4,
      children: _children,
    );
  }
}

class _SliverTagsWidget extends TagsWidget {
  const _SliverTagsWidget({
    super.key,
    required super.tags,
    super.isClickable,
    super.showShortNames,
    super.dense,
    super.onTagSelected,
    super.maxTags,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList.list(
      children: _children,
    );
  }
}
