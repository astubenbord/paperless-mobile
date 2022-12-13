import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/offline_banner.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/bulk_delete_confirmation_dialog.dart';
import 'package:paperless_mobile/features/saved_view/view/saved_view_selection_widget.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class DocumentsPageAppBar extends StatefulWidget with PreferredSizeWidget {
  final List<Widget> actions;
  final bool isOffline;

  const DocumentsPageAppBar({
    super.key,
    required this.isOffline,
    this.actions = const [],
  });
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  State<DocumentsPageAppBar> createState() => _DocumentsPageAppBarState();
}

class _DocumentsPageAppBarState extends State<DocumentsPageAppBar> {
  @override
  Widget build(BuildContext context) {
    const savedViewWidgetHeight = 48.0;
    final flexibleAreaHeight = kToolbarHeight -
        16 +
        savedViewWidgetHeight +
        (widget.isOffline ? 24 : 0);
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (context, documentsState) {
        final hasSelection = documentsState.selection.isNotEmpty;
        if (hasSelection) {
          return SliverAppBar(
            expandedHeight: kToolbarHeight + flexibleAreaHeight,
            snap: true,
            floating: true,
            pinned: true,
            flexibleSpace: _buildFlexibleArea(
              false,
              documentsState.filter,
              savedViewWidgetHeight,
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  BlocProvider.of<DocumentsCubit>(context).resetSelection(),
            ),
            title: Text(
                '${documentsState.selection.length} ${S.of(context).documentsSelectedText}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _onDelete(context, documentsState),
              ),
            ],
          );
        } else {
          return SliverAppBar(
            expandedHeight: kToolbarHeight + flexibleAreaHeight,
            snap: true,
            floating: true,
            pinned: true,
            flexibleSpace: _buildFlexibleArea(
              true,
              documentsState.filter,
              savedViewWidgetHeight,
            ),
            title: Text(
              '${S.of(context).documentsPageTitle} (${_formatDocumentCount(documentsState.count)})',
            ),
            actions: [
              ...widget.actions,
            ],
          );
        }
      },
    );
  }

  Widget _buildFlexibleArea(
    bool enabled,
    DocumentFilter filter,
    double savedViewHeight,
  ) {
    return FlexibleSpaceBar(
      background: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.isOffline) const OfflineBanner(),
          SavedViewSelectionWidget(
            height: savedViewHeight,
            enabled: enabled,
            currentFilter: filter,
          ).paddedSymmetrically(horizontal: 8.0),
        ],
      ),
    );
  }

  void _onDelete(BuildContext context, DocumentsState documentsState) async {
    final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) =>
                BulkDeleteConfirmationDialog(state: documentsState)) ??
        false;
    if (shouldDelete) {
      try {
        await BlocProvider.of<DocumentsCubit>(context)
            .bulkRemove(documentsState.selection);
        showSnackBar(
          context,
          S.of(context).documentsPageBulkDeleteSuccessfulText,
        );
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  String _formatDocumentCount(int count) {
    return count > 99 ? "99+" : count.toString();
  }
}
