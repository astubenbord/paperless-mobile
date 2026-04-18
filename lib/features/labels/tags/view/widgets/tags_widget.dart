import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/repository/tag_repository.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tag_widget.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TagsWidget extends StatelessWidget {
  final void Function(int tagId)? onTagSelected;
  final List<int>? tagIds;
  final bool isClickable;
  final bool showShortNames;
  final bool dense;

  const TagsWidget({
    super.key,
    required this.tagIds,
    this.onTagSelected,
    this.isClickable = true,
    this.showShortNames = false,
    this.dense = true,
  });

  const factory TagsWidget.multiLine({
    Key? key,
    required void Function(int tagId)? onTagSelected,
    required bool isClickable,
    required bool showShortNames,
    required bool dense,
    required List<int>? tagIds,
  }) = _MultiLineTagsWidget;

  const factory TagsWidget.sliver({
    Key? key,
    void Function(int tagId)? onTagSelected,
    bool isClickable,
    bool showShortNames,
    bool dense,
    required List<int> tagIds,
  }) = _SliverTagsWidget;

  @override
  Widget build(BuildContext context) {
    // Show skeleton when tagIds are not yet available
    if (tagIds == null) {
      return _TagsSkeletonWidget(
        skeletonCount: _kDefaultSkeletonCount,
        dense: dense,
      );
    }

    return QueryBuilder(
      query: context.tagRepository.getAllQuery(),
      builder: (context, state) {
        if (state.isError) {
          return Text(
            'Could not load tags. ${state.error}',
          ); // TODO: INTL/error handling
        }

        // Show skeleton while loading tag data
        if (state.isLoadingInitial) {
          return _TagsSkeletonWidget(
            skeletonCount: tagIds!.length,
            dense: dense,
          );
        }

        final tags = state.data;
        if (tags == null) {
          return const SizedBox.shrink();
        }

        final mappedTags = _mapTagIds(tagIds!, tags);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tag in mappedTags)
                TagWidget(
                  tag: tag,
                  isClickable: isClickable,
                  onSelected: () => onTagSelected?.call(tag.id),
                  showShortName: showShortNames,
                  dense: dense,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MultiLineTagsWidget extends TagsWidget {
  const _MultiLineTagsWidget({
    super.key,
    required super.tagIds,
    super.onTagSelected,
    super.isClickable,
    super.showShortNames,
    super.dense,
  });

  @override
  Widget build(BuildContext context) {
    // Show skeleton when tagIds are not yet available
    if (tagIds == null) {
      return _MultiLineTagsSkeletonWidget(
        skeletonCount: _kDefaultSkeletonCount,
        dense: dense,
      );
    }

    return QueryBuilder(
      query: context.read<TagRepository>().getAllQuery(),
      builder: (context, state) {
        if (state.isError) {
          return Text('Could not load tags.'); // TODO: INTL/error handling
        }

        // Show skeleton while loading tag data
        if (state.isLoadingInitial) {
          return _MultiLineTagsSkeletonWidget(
            skeletonCount: tagIds!.length,
            dense: dense,
          );
        }

        final tags = state.data;
        if (tags == null) {
          return const SizedBox.shrink();
        }

        final mappedTags = _mapTagIds(tagIds!, tags);

        return Wrap(
          runAlignment: WrapAlignment.start,
          runSpacing: 4,
          spacing: 4,
          children: [
            for (final tag in mappedTags)
              TagWidget(
                tag: tag,
                isClickable: isClickable,
                onSelected: () => onTagSelected?.call(tag.id),
                showShortName: showShortNames,
                dense: dense,
              ),
          ],
        );
      },
    );
  }
}

class _SliverTagsWidget extends TagsWidget {
  const _SliverTagsWidget({
    super.key,
    required super.tagIds,
    super.isClickable,
    super.showShortNames,
    super.dense,
    super.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Show skeleton when tagIds are not yet available
    if (tagIds == null) {
      return _SliverTagsSkeletonWidget(
        skeletonCount: _kDefaultSkeletonCount,
        dense: dense,
      );
    }

    return QueryBuilder(
      query: context.read<TagRepository>().getAllQuery(),
      builder: (context, state) {
        if (state.isError) {
          return SliverToBoxAdapter(
            child: Text('Could not load tags.'), // TODO: INTL/error handling
          );
        }

        // Show skeleton while loading tag data
        if (state.isLoadingInitial) {
          return _SliverTagsSkeletonWidget(
            skeletonCount: tagIds!.length,
            dense: dense,
          );
        }

        final tags = state.data;
        if (tags == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final mappedTags = _mapTagIds(tagIds!, tags);

        return SliverList.list(
          children: [
            for (final tag in mappedTags)
              TagWidget(
                tag: tag,
                isClickable: isClickable,
                onSelected: () => onTagSelected?.call(tag.id),
                showShortName: showShortNames,
                dense: dense,
              ),
          ],
        );
      },
    );
  }
}

// --- Skeleton Widgets ---

const int _kDefaultSkeletonCount = 3;

class _TagsSkeletonWidget extends StatelessWidget {
  final int skeletonCount;
  final bool dense;

  const _TagsSkeletonWidget({required this.skeletonCount, required this.dense});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 4,
          children: List.generate(
            skeletonCount,
            (_) => _SkeletonTagChip(dense: dense),
          ),
        ),
      ),
    );
  }
}

class _MultiLineTagsSkeletonWidget extends StatelessWidget {
  final int skeletonCount;
  final bool dense;

  const _MultiLineTagsSkeletonWidget({
    required this.skeletonCount,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Wrap(
        runAlignment: WrapAlignment.start,
        runSpacing: 4,
        spacing: 4,
        children: List.generate(
          skeletonCount,
          (_) => _SkeletonTagChip(dense: dense),
        ),
      ),
    );
  }
}

class _SliverTagsSkeletonWidget extends StatelessWidget {
  final int skeletonCount;
  final bool dense;

  const _SliverTagsSkeletonWidget({
    required this.skeletonCount,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: true,
      child: SliverList.list(
        children: List.generate(
          skeletonCount,
          (_) => _SkeletonTagChip(dense: dense),
        ),
      ),
    );
  }
}

class _SkeletonTagChip extends StatelessWidget {
  final bool dense;

  const _SkeletonTagChip({required this.dense});

  @override
  Widget build(BuildContext context) {
    return Skeleton.shade(
      child: Chip(
        label: Text(BoneMock.words(1)),
        padding: dense ? const EdgeInsets.all(4) : null,
        visualDensity: const VisualDensity(vertical: -2),
        labelPadding: dense ? const EdgeInsets.symmetric(horizontal: 2) : null,
        side: BorderSide.none,
      ),
    );
  }
}

// --- Helper Functions ---

List<Tag> _mapTagIds(List<int> tagIds, Iterable<Tag> tags) {
  final tagMap = {for (final tag in tags) tag.id: tag};
  return tagIds
      .where((id) => tagMap.containsKey(id))
      .map((id) => tagMap[id]!)
      .toList();
}
