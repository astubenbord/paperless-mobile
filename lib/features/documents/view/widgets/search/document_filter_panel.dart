import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/document_filter_form.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

enum DateRangeSelection { before, after }

class DocumentFilterPanel extends StatefulWidget {
  final DocumentFilter initialFilter;
  final ScrollController scrollController;
  final DraggableScrollableController draggableSheetController;

  const DocumentFilterPanel({
    super.key,
    required this.initialFilter,
    required this.scrollController,
    required this.draggableSheetController,
  });

  @override
  State<DocumentFilterPanel> createState() => _DocumentFilterPanelState();
}

class _DocumentFilterPanelState extends State<DocumentFilterPanel> {
  final _formKey = GlobalKey<FormBuilderState>();

  double _heightAnimationValue = 0;

  @override
  void initState() {
    super.initState();

    widget.draggableSheetController.addListener(animateTitleByDrag);
  }

  void animateTitleByDrag() {
    setState(
      () => _heightAnimationValue =
          dp(((max(0.9, widget.draggableSheetController.size) - 0.9) / 0.1), 5),
    );
  }

  bool get isDockedToTop => _heightAnimationValue == 1;

  @override
  void dispose() {
    widget.draggableSheetController.removeListener(animateTitleByDrag);
    super.dispose();
  }

  /// Rounds double to [places] decimal places.
  double dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  @override
  Widget build(BuildContext context) {
    final double radius = (1 - max(0, (_heightAnimationValue) - 0.5) * 2) * 16;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        backgroundColor: Theme.of(context).colorScheme.surface,
        floatingActionButton: Visibility(
          visible: MediaQuery.of(context).viewInsets.bottom == 0,
          child: FloatingActionButton.extended(
            heroTag: "fab_document_filter_panel",
            icon: const Icon(Icons.done),
            label: Text(S.of(context)!.apply),
            onPressed: _onApplyFilter,
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.refresh),
                label: Text(S.of(context)!.reset),
              ),
            ],
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: DocumentFilterForm(
          formKey: _formKey,
          scrollController: widget.scrollController,
          initialFilter: widget.initialFilter,
          header: _buildPanelHeader(),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight + 22,
      title: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Opacity(
              opacity: 1 - _heightAnimationValue,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _buildDragHandle(),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Opacity(
                    opacity: max(0, (_heightAnimationValue - 0.5) * 2),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: _heightAnimationValue * 48),
                    child: Text(S.of(context)!.filterDocuments),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildDragHandle() {
    return Container(
      // According to m3 spec https://m3.material.io/components/bottom-sheets/specs
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(102),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Future<void> _resetFilter() async {
    FocusScope.of(context).unfocus();
    Navigator.pop(
      context,
      DocumentFilterIntent(shouldReset: true),
    );
  }

  Future<void> _onApplyFilter() async {
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      DocumentFilter newFilter =
          DocumentFilterForm.assembleFilter(_formKey, widget.initialFilter);
      FocusScope.of(context).unfocus();
      Navigator.pop(context, DocumentFilterIntent(filter: newFilter));
    }
  }
}
