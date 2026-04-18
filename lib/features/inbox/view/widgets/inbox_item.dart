import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/dart_extensions.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/extensions/label_list_extension.dart';
import 'package:paperless_mobile/core/repository/document_repository.dart';
import 'package:paperless_mobile/core/widgets/icon_loading_widget.dart';
import 'package:paperless_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/tags_placeholder.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/text_placeholder.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/document_type/view/widgets/document_type_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';

class InboxItemPlaceholder extends StatelessWidget {
  const InboxItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextPlaceholder(length: 150, fontSize: 12),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: const ColoredBox(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Spacer(),
                            TextPlaceholder(length: 200, fontSize: 14),
                            Spacer(),
                            TextPlaceholder(length: 120, fontSize: 14),
                            SizedBox(height: 8),
                            TextPlaceholder(length: 170, fontSize: 14),
                            Spacer(),
                            TagsPlaceholder(count: 3, dense: true),
                            Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: IntrinsicHeight(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 40,
                            child: ColoredBox(color: Colors.white),
                          ).padded(),
                          const VerticalDivider(indent: 12, endIndent: 12),
                          SizedBox(
                            height: 40,
                            child: Row(
                              children: [
                                Container(
                                  width: 150,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 200,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InboxItem extends StatefulWidget {
  static const a4AspectRatio = 1 / 1.4142;
  final Document document;
  const InboxItem({super.key, required this.document});

  @override
  State<InboxItem> createState() => _InboxItemState();
}

class _InboxItemState extends State<InboxItem> {
  //TODO: This may be removed if a skip-like option is added to QueryBuilder
  /// Suggestions are initially disabled to avoid unnecessary API calls
  /// and enabled (and therefore also subscribed to changes) when the user requests suggestions.
  late bool _suggestionsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final formattedCreatedDate = widget.document.created != null
        ? context.displayDateFormat.format(widget.document.created!)
        : null;
    return ChipTheme(
      data: Theme.of(context).chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          DocumentDetailsRoute(
            title: widget.document.title,
            documentId: widget.document.id,
            thumbnailUrl: widget.document.buildThumbnailUrl(context),
            isLabelClickable: false,
            heroTagPrefix: 'inbox_item',
          ).push(context);
        },
        child: SizedBox(
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Row(
                  children: [
                    AspectRatio(
                      aspectRatio: InboxItem.a4AspectRatio,
                      child: DocumentPreview(
                        documentId: widget.document.id,
                        title: widget.document.title,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        heroTagPrefix: 'inbox_item',
                      ),
                    ).padded(),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CorrespondentWidget(
                            id: widget.document.correspondent,
                            isClickable: false,
                          ).paddedOnly(left: 8, right: 8, top: 8),
                          Text(
                            widget.document.title ?? '-',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.titleSmall,
                          ).paddedOnly(left: 8, right: 8),
                          const Spacer(),
                          Row(
                            spacing: 4,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(200),
                              ),
                              DocumentTypeWidget(
                                id: widget.document.documentType,
                                isClickable: false,
                              ),
                            ],
                          ).paddedSymmetrically(horizontal: 8),
                          Row(
                            spacing: 4,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(200),
                              ),
                              Text(formattedCreatedDate ?? '-'),
                            ],
                          ).paddedSymmetrically(horizontal: 8),
                          const Spacer(),
                          TagsWidget(
                            tagIds: widget.document.tags,
                            isClickable: false,
                          ).paddedOnly(left: 8, bottom: 8),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              LimitedBox(
                maxHeight: 56,
                child: ConnectivityAwareActionWrapper(
                  child: _buildActions(context),
                ),
              ),
            ],
          ).paddedOnly(left: 8, top: 8, bottom: 8),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final canEdit = context.uiSettings$.canEditDocuments;
    final canDelete = context.uiSettings$.canDeleteDocuments;
    final actions = [
      if (canEdit)
        ActionChip(
          avatar: const Icon(Icons.edit_outlined),
          label: Text(S.of(context)!.editDocument),
          onPressed: () {
            EditDocumentRoute(documentId: widget.document.id).push(context);
          },
        ).paddedOnly(right: 4),
      if (canEdit) _buildAssignAsnAction(context),
      // if (canEdit && canDelete) const SizedBox(width: 8.0),
      if (canDelete)
        ActionChip(
          avatar: const Icon(Icons.delete_outline),
          label: Text(S.of(context)!.deleteDocument),
          onPressed: () async {
            final shouldDelete =
                await showDialog<bool>(
                  useRootNavigator: false,
                  context: context,
                  builder: (context) => DeleteDocumentConfirmationDialog(
                    document: widget.document,
                  ),
                ) ??
                false;
            if (shouldDelete && context.mounted) {
              await context.documentRepository
                  .deleteDocumentMutation(widget.document.id)
                  .mutate();
            }
          },
        ).paddedOnly(right: 4),
    ].map((a) => SliverToBoxAdapter(child: a)).toList();

    if (actions.isEmpty) {
      return SliverToBoxAdapter(child: const SizedBox.shrink());
    }
    return CustomScrollView(
      scrollDirection: Axis.horizontal,
      slivers: [
        SliverToBoxAdapter(
          child: QueryConsumer(
            listenWhen: (oldState, newState) =>
                newState.timeCreated != oldState.timeCreated &&
                newState.isSuccess,
            listener: (state) {
              if (state.data != null) {
                final hasSuggestions =
                    state.data!.correspondents.isNotEmpty ||
                    state.data!.documentTypes.isNotEmpty ||
                    state.data!.tags.isNotEmpty ||
                    state.data!.storagePaths.isNotEmpty ||
                    state.data!.dates.isNotEmpty;
                if (hasSuggestions) {
                  showSnackBar(
                    context,
                    S.of(context)!.noSuggestionsForThisDocument,
                  );
                }
              }
            },
            query: context.documentRepository.getFieldSuggestionsQuery(
              widget.document.id,
            ),
            enabled: _suggestionsEnabled,
            builder: (context, state) {
              if (state.data != null) {
                return ActionChip(
                  avatar: state.isLoading
                      ? IconLoadingWidget()
                      : const Icon(Icons.refresh),
                  label: Text(S.of(context)!.inboxItemReloadSuggestions),
                  onPressed: () {
                    setState(() {
                      _suggestionsEnabled = true;
                    });
                    context.documentRepository
                        .getFieldSuggestionsQuery(widget.document.id)
                        .refetch();
                  },
                ).paddedOnly(right: 4);
              }
              return ActionChip(
                avatar: state.isLoading
                    ? IconLoadingWidget()
                    : const Icon(Icons.auto_awesome),
                onPressed: () {
                  setState(() {
                    _suggestionsEnabled = true;
                  });
                  context.documentRepository
                      .getFieldSuggestionsQuery(widget.document.id)
                      .fetch();
                },
                label: Text(S.of(context)!.loadInboxItemSuggestions),
              ).paddedOnly(right: 4);
            },
          ),
        ),
        _buildSuggestionChips(context),
        ...actions,
      ],
    );
  }

  Widget _buildAssignAsnAction(BuildContext context) {
    final hasAsn = widget.document.archiveSerialNumber != null;
    if (hasAsn) {
      return SizedBox.shrink();
    }
    return MutationConsumer(
      mutation: context.documentRepository.assignAsnMutation(
        widget.document.id,
      ),
      listenWhen: (oldState, newState) {
        return oldState.runtimeType != newState.runtimeType;
      },
      listener: (state) {
        if (state is MutationSuccess && context.mounted) {
          showSnackBar(context, S.of(context)!.archiveSerialNumberUpdated);
        }
      },
      builder: (context, state, mutate) {
        if (state is MutationSuccess) {
          // If the ASN has been assigned, we don't need to show the action anymore
          return SizedBox.shrink();
        }
        return ActionChip(
          avatar: state.isLoading ? IconLoadingWidget() : null,
          label: Text(S.of(context)!.assignAsn),
          onPressed: () => mutate(AssignAsnRequest(auto: true)),
        ).paddedOnly(right: 4);
      },
    );
  }

  Widget _buildSuggestionChips(BuildContext context) {
    final chipColor = Theme.of(context).colorScheme.secondary;
    final chipForegroundColor = Theme.of(context).colorScheme.onSecondary;
    return QueryBuilder(
      query: context.documentRepository.getFieldSuggestionsQuery(
        widget.document.id,
      ),
      enabled: _suggestionsEnabled,
      builder: (context, state) {
        if (state.isInitial || state.isLoadingInitial) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }
        if (state.isError) {
          return SliverToBoxAdapter(
            child: Center(child: Text(S.of(context)!.couldNotLoadSuggestions)),
          );
        }
        final suggestions = state.data!;

        return SliverList.list(
          children: [
            if (context.uiSettings$.canViewCorrespondents)
              ...suggestions.correspondents
                  .whereNot((e) => widget.document.correspondent == e)
                  .map(
                    (e) => QueryBuilder(
                      query: context.correspondentRepository.getAllQuery(),
                      builder: (context, state) {
                        final correspondents = state.data?.toIdMap();
                        return ActionChip(
                          backgroundColor: chipColor,
                          avatar: Icon(
                            Icons.person_outline,
                            color: chipForegroundColor,
                          ),
                          label: Text(
                            correspondents?[e]?.name ?? '',
                            style: TextStyle(color: chipForegroundColor),
                          ),
                          onPressed: () async {
                            await context.documentRepository
                                .patchDocumentMutation(widget.document.id)
                                .mutate(
                                  PatchedDocumentRequest(
                                    correspondent: PatchedValue(e),
                                  ),
                                );
                            if (context.mounted) {
                              showSnackBar(
                                context,
                                S.of(context)!.suggestionSuccessfullyApplied,
                              );
                            }
                          },
                        ).paddedOnly(right: 4);
                      },
                    ),
                  ),
            if (context.uiSettings$.canViewDocumentTypes)
              ...suggestions.documentTypes
                  .whereNot((e) => widget.document.documentType == e)
                  .map(
                    (e) => QueryBuilder(
                      query: context.documentTypeRepository.getAllQuery(),
                      builder: (context, state) {
                        final documentTypes = state.data?.toIdMap();
                        return ActionChip(
                          backgroundColor: chipColor,
                          avatar: Icon(
                            Icons.description_outlined,
                            color: chipForegroundColor,
                          ),
                          label: Text(
                            documentTypes?[e]?.name ?? '',
                            style: TextStyle(color: chipForegroundColor),
                          ),
                          onPressed: () async {
                            await context.documentRepository
                                .patchDocumentMutation(widget.document.id)
                                .mutate(
                                  PatchedDocumentRequest(
                                    documentType: PatchedValue(e),
                                  ),
                                );
                            if (context.mounted) {
                              showSnackBar(
                                context,
                                S.of(context)!.suggestionSuccessfullyApplied,
                              );
                            }
                          },
                        ).paddedOnly(right: 4);
                      },
                    ),
                  ),
            if (context.uiSettings$.canViewTags)
              ...suggestions.tags
                  .whereNot((e) => widget.document.tags?.contains(e) ?? false)
                  .map(
                    (e) => QueryBuilder(
                      query: context.tagRepository.getAllQuery(),
                      builder: (context, state) {
                        final tags = state.data?.toIdMap();
                        return ActionChip(
                          backgroundColor: chipColor,
                          avatar: Icon(
                            Icons.label_outline,
                            color: chipForegroundColor,
                          ),
                          label: Text(
                            tags?[e]?.name ?? '',
                            style: TextStyle(color: chipForegroundColor),
                          ),
                          onPressed: () async {
                            await context.documentRepository
                                .patchDocumentMutation(widget.document.id)
                                .mutate(
                                  PatchedDocumentRequest(
                                    tags: PatchedValue(
                                      {...?widget.document.tags, e}.toList(),
                                    ),
                                  ),
                                );
                            if (context.mounted) {
                              showSnackBar(
                                context,
                                S.of(context)!.suggestionSuccessfullyApplied,
                              );
                            }
                          },
                        ).paddedOnly(right: 4);
                      },
                    ),
                  ),
            if (context.uiSettings$.canViewStoragePaths)
              ...suggestions.storagePaths
                  .whereNot((e) => widget.document.storagePath == e)
                  .map(
                    (e) => QueryBuilder(
                      query: context.storagePathRepository.getAllQuery(),
                      builder: (context, state) {
                        final storagePaths = state.data?.toIdMap();
                        return ActionChip(
                          avatar: Icon(
                            Icons.label_outline,
                            color: chipForegroundColor,
                          ),
                          label: Text(
                            storagePaths?[e]?.name ?? '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                          onPressed: () async {
                            await context.documentRepository
                                .patchDocumentMutation(widget.document.id)
                                .mutate(
                                  PatchedDocumentRequest(
                                    storagePath: PatchedValue(e),
                                  ),
                                );
                            if (context.mounted) {
                              showSnackBar(
                                context,
                                S.of(context)!.suggestionSuccessfullyApplied,
                              );
                            }
                          },
                        ).paddedOnly(right: 4);
                      },
                    ),
                  ),
            ...suggestions.dates
                .map(DateTime.parse)
                .whereNot(
                  (e) => widget.document.created?.isOnSameDayAs(e) ?? false,
                )
                .map(
                  (e) => ActionChip(
                    avatar: Icon(
                      Icons.calendar_today,
                      color: chipForegroundColor,
                    ),
                    label: Text(
                      "${S.of(context)!.createdAt}: ${context.displayDateFormat.format(e)}",
                      style: TextStyle(color: chipForegroundColor),
                    ),
                    onPressed: () async {
                      await context.documentRepository
                          .patchDocumentMutation(widget.document.id)
                          .mutate(
                            PatchedDocumentRequest(created: PatchedValue(e)),
                          );
                      if (context.mounted) {
                        showSnackBar(
                          context,
                          S.of(context)!.suggestionSuccessfullyApplied,
                        );
                      }
                    },
                  ).paddedOnly(right: 4),
                ),
          ],
        );
      },
    );
  }
}
