import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/document_extensions.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/util/lambda_utils.dart';
import 'package:paperless_mobile/core/widgets/shimmer_placeholder.dart';
import 'package:paperless_mobile/core/widgets/colored_chip.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/delete_document_confirmation_dialog.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/tags_placeholder.dart';
import 'package:paperless_mobile/features/documents/view/widgets/placeholder/text_placeholder.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_text.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/widgets/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:hive_ce_flutter/adapters.dart';
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
          const SizedBox(
            height: 16,
          ),
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
                          child: const ColoredBox(
                            color: Colors.white,
                          ),
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
                            child: ColoredBox(
                              color: Colors.white,
                            ),
                          ).padded(),
                          const VerticalDivider(
                            indent: 12,
                            endIndent: 12,
                          ),
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
  final DocumentModel document;
  const InboxItem({
    super.key,
    required this.document,
  });

  @override
  State<InboxItem> createState() => _InboxItemState();
}

class _InboxItemState extends State<InboxItem> {
  bool _isAsnAssignLoading = false;
  FieldSuggestions? _suggestions;
  bool _suggestionsLoading = false;
  bool _suggestionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (_suggestionsLoaded || _suggestionsLoading) return;
    final settings = Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue();
    if (settings != null && !settings.showAiSuggestions) return;
    setState(() => _suggestionsLoading = true);
    try {
      final suggestions = await context
          .read<PaperlessDocumentsApi>()
          .findSuggestions(widget.document);
      if (mounted) {
        setState(() {
          _suggestions = suggestions.documentDifference(widget.document);
          _suggestionsLoading = false;
          _suggestionsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suggestionsLoading = false;
          _suggestionsLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelRepository = context.read<LabelRepository>();
    return BlocBuilder<InboxCubit, InboxState>(
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            DocumentDetailsRoute(
              title: widget.document.title,
              id: widget.document.id,
              thumbnailUrl: widget.document.buildThumbnailUrl(context),
              isLabelClickable: false,
            ).push(context);
          },
          child: SizedBox(
            height: 200,
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
                          enableHero: false,
                        ),
                      ).padded(),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitle().paddedOnly(left: 8, right: 8, top: 8),
                            const Spacer(),
                            _buildTextWithLeadingIcon(
                              Icon(
                                Icons.person_outline,
                                size: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontSize,
                              ),
                              LabelText<Correspondent>(
                                label: labelRepository.correspondents[
                                    widget.document.correspondent],
                                style: Theme.of(context).textTheme.bodyMedium,
                                placeholder: "-",
                              ),
                            ).paddedSymmetrically(horizontal: 8),
                            _buildTextWithLeadingIcon(
                              Icon(
                                Icons.description_outlined,
                                size: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontSize,
                              ),
                              LabelText<DocumentType>(
                                label: labelRepository.documentTypes[
                                    widget.document.documentType],
                                style: Theme.of(context).textTheme.bodyMedium,
                                placeholder: "-",
                              ),
                            ).paddedSymmetrically(horizontal: 8),
                            _buildTextWithLeadingIcon(
                              Icon(
                                Icons.calendar_today,
                                size: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontSize,
                              ),
                              Text(
                                DateFormat.yMMMd(
                                  Localizations.localeOf(context).toString(),
                                ).format(widget.document.created),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ).paddedSymmetrically(horizontal: 8),
                            const Spacer(),
                            TagsWidget(
                              tags: widget.document.tags
                                  .map((e) => labelRepository.tags[e])
                                  .where(isNotNull)
                                  .toList()
                                  .cast<Tag>(),
                              isClickable: false,
                              showShortNames: true,
                            ).paddedOnly(left: 8, bottom: 8),
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
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    final currentUser = context.watch<LocalUserAccount>().paperlessUser;
    final labelRepository = context.read<LabelRepository>();
    final canEdit = currentUser.canEditDocuments;
    final canDelete = currentUser.canDeleteDocuments;
    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32),
    );
    final actions = [
      if (canEdit) _buildAssignAsnAction(chipShape, context),
      if (canEdit && canDelete) const SizedBox(width: 8.0),
      if (canDelete)
        ColoredChipWrapper(
          child: ActionChip(
            avatar: const Icon(Icons.delete_outline),
            shape: chipShape,
            label: Text(S.of(context)!.deleteDocument),
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => DeleteDocumentConfirmationDialog(
                        document: widget.document),
                  ) ??
                  false;
              if (shouldDelete && context.mounted) {
                context.read<InboxCubit>().delete(widget.document);
              }
            },
          ),
        ),
    ];
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 50,
              ),
              child: Text(
                S.of(context)!.quickAction,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            const VerticalDivider(
              indent: 16,
              endIndent: 16,
            ),
          ],
        ),
        const SizedBox(width: 4.0),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...actions,
              if (_suggestions != null && _suggestions!.hasSuggestions)
                ..._buildSuggestionChips(chipShape, labelRepository),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignAsnAction(
    RoundedRectangleBorder chipShape,
    BuildContext context,
  ) {
    final hasAsn = widget.document.archiveSerialNumber != null;
    return ColoredChipWrapper(
      child: ActionChip(
        avatar: _isAsnAssignLoading
            ? const CircularProgressIndicator()
            : hasAsn
                ? null
                : const Icon(Icons.archive_outlined),
        shape: chipShape,
        label: hasAsn
            ? Text(
                '${S.of(context)!.asn} #${widget.document.archiveSerialNumber}',
              )
            : Text(S.of(context)!.assignAsn),
        onPressed: !hasAsn
            ? () {
                setState(() {
                  _isAsnAssignLoading = true;
                });

                context
                    .read<InboxCubit>()
                    .assignAsn(widget.document)
                    .whenComplete(
                      () => setState(() => _isAsnAssignLoading = false),
                    );
              }
            : null,
      ),
    );
  }

  Text _buildTitle() {
    return Text(
      widget.document.title.isEmpty ? '-' : widget.document.title,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  Row _buildTextWithLeadingIcon(Icon icon, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 2),
        Flexible(
          child: child,
        ),
      ],
    );
  }

  List<Widget> _buildSuggestionChips(
    RoundedRectangleBorder chipShape,
    LabelRepository labelRepository,
  ) {
    final suggestions = _suggestions!;
    final chips = <Widget>[];

    for (final e in suggestions.correspondents) {
      final name = labelRepository.correspondents[e]?.name;
      if (name == null) continue;
      chips.add(ColoredChipWrapper(
        child: ActionChip(
          avatar: const Icon(Icons.person_outline),
          shape: chipShape,
          label: Text(name),
          onPressed: () {
            context
                .read<InboxCubit>()
                .update(widget.document.copyWith(correspondent: () => e))
                .then((_) {
              if (mounted) {
                showSnackBar(
                    context, S.of(context)!.suggestionSuccessfullyApplied);
              }
            });
          },
        ),
      ));
    }

    for (final e in suggestions.documentTypes) {
      final name = labelRepository.documentTypes[e]?.name;
      if (name == null) continue;
      chips.add(ColoredChipWrapper(
        child: ActionChip(
          avatar: const Icon(Icons.description_outlined),
          shape: chipShape,
          label: Text(name),
          onPressed: () {
            context
                .read<InboxCubit>()
                .update(widget.document.copyWith(documentType: () => e))
                .then((_) {
              if (mounted) {
                showSnackBar(
                    context, S.of(context)!.suggestionSuccessfullyApplied);
              }
            });
          },
        ),
      ));
    }

    for (final e in suggestions.tags) {
      final name = labelRepository.tags[e]?.name;
      if (name == null) continue;
      chips.add(ColoredChipWrapper(
        child: ActionChip(
          avatar: const Icon(Icons.label_outline),
          shape: chipShape,
          label: Text(name),
          onPressed: () {
            context
                .read<InboxCubit>()
                .update(widget.document.copyWith(
                  tags: {...widget.document.tags, e}.toList(),
                ))
                .then((_) {
              if (mounted) {
                showSnackBar(
                    context, S.of(context)!.suggestionSuccessfullyApplied);
              }
            });
          },
        ),
      ));
    }

    for (final e in suggestions.dates) {
      chips.add(ColoredChipWrapper(
        child: ActionChip(
          avatar: const Icon(Icons.calendar_today_outlined),
          shape: chipShape,
          label: Text(
            "${S.of(context)!.createdAt}: ${DateFormat.yMd().format(e)}",
          ),
          onPressed: () {
            context
                .read<InboxCubit>()
                .update(widget.document.copyWith(created: e))
                .then((_) {
              if (mounted) {
                showSnackBar(
                    context, S.of(context)!.suggestionSuccessfullyApplied);
              }
            });
          },
        ),
      ));
    }

    if (chips.length > 1) {
      chips.insert(
        0,
        ColoredChipWrapper(
          child: ActionChip(
            avatar: const Icon(Icons.auto_awesome),
            shape: chipShape,
            label: Text(S.of(context)!.acceptAllSuggestions),
            onPressed: () => _acceptAllSuggestions(suggestions),
          ),
        ),
      );
    }

    return chips
        .expand((chip) => [chip, const SizedBox(width: 4)])
        .toList();
  }

  Future<void> _acceptAllSuggestions(FieldSuggestions suggestions) async {
    var doc = widget.document;
    if (suggestions.correspondents.isNotEmpty) {
      doc = doc.copyWith(
          correspondent: () => suggestions.correspondents.first);
    }
    if (suggestions.documentTypes.isNotEmpty) {
      doc = doc.copyWith(
          documentType: () => suggestions.documentTypes.first);
    }
    if (suggestions.tags.isNotEmpty) {
      doc = doc.copyWith(
        tags: {...doc.tags, ...suggestions.tags}.toList(),
      );
    }
    if (suggestions.dates.isNotEmpty) {
      doc = doc.copyWith(created: suggestions.dates.first);
    }
    await context.read<InboxCubit>().update(doc);
    if (mounted) {
      showSnackBar(context, S.of(context)!.suggestionSuccessfullyApplied);
    }
  }
}
