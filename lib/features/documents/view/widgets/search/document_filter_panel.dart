import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/form_builder_extended_date_range_picker.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/text_query_form_field.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';

enum DateRangeSelection { before, after }

class DocumentFilterPanel extends StatefulWidget {
  final DocumentFilter initialFilter;
  final ScrollController scrollController;
  final DraggableScrollableController draggableSheetController;
  const DocumentFilterPanel({
    Key? key,
    required this.initialFilter,
    required this.scrollController,
    required this.draggableSheetController,
  }) : super(key: key);

  @override
  State<DocumentFilterPanel> createState() => _DocumentFilterPanelState();
}

class _DocumentFilterPanelState extends State<DocumentFilterPanel> {
  static const fkCorrespondent = DocumentModel.correspondentKey;
  static const fkDocumentType = DocumentModel.documentTypeKey;
  static const fkStoragePath = DocumentModel.storagePathKey;
  static const fkQuery = "query";
  static const fkCreatedAt = DocumentModel.createdKey;
  static const fkAddedAt = DocumentModel.addedKey;

  final _formKey = GlobalKey<FormBuilderState>();
  late bool _allowOnlyExtendedQuery;

  double _heightAnimationValue = 0;

  @override
  void initState() {
    super.initState();
    _allowOnlyExtendedQuery = widget.initialFilter.forceExtendedQuery;
    widget.draggableSheetController.addListener(animateTitleByDrag);
  }

  void animateTitleByDrag() {
    setState(
      () {
        _heightAnimationValue = dp(
            ((max(0.9, widget.draggableSheetController.size) - 0.9) / 0.1), 5);
      },
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
            icon: const Icon(Icons.done),
            label: Text(S.of(context).documentFilterApplyFilterLabel),
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
                label: Text(S.of(context).documentFilterResetLabel),
              ),
            ],
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: FormBuilder(
          key: _formKey,
          child: _buildFormList(context),
        ),
      ),
    );
  }

  Widget _buildFormList(BuildContext context) {
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverAppBar(
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
                    padding: EdgeInsets.only(bottom: 11),
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
                        padding:
                            EdgeInsets.only(left: _heightAnimationValue * 48),
                        child: Text(S.of(context).documentFilterTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ..._buildFormFieldList(),
      ],
    );
  }

  List<Widget> _buildFormFieldList() {
    return [
      _buildQueryFormField().paddedSymmetrically(vertical: 8, horizontal: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          S.of(context).documentFilterAdvancedLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ).paddedSymmetrically(vertical: 8, horizontal: 16),
      FormBuilderExtendedDateRangePicker(
        name: fkCreatedAt,
        initialValue: widget.initialFilter.created,
        labelText: S.of(context).documentCreatedPropertyLabel,
        onChanged: (_) {
          _checkQueryConstraints();
        },
      ).paddedSymmetrically(vertical: 8, horizontal: 16),
      FormBuilderExtendedDateRangePicker(
        name: fkAddedAt,
        initialValue: widget.initialFilter.added,
        labelText: S.of(context).documentAddedPropertyLabel,
        onChanged: (_) {
          _checkQueryConstraints();
        },
      ).paddedSymmetrically(vertical: 8, horizontal: 16),
      _buildCorrespondentFormField()
          .paddedSymmetrically(vertical: 8, horizontal: 16),
      _buildDocumentTypeFormField()
          .paddedSymmetrically(vertical: 8, horizontal: 16),
      _buildStoragePathFormField()
          .paddedSymmetrically(vertical: 8, horizontal: 16),
      _buildTagsFormField().padded(16),
    ].map((w) => SliverToBoxAdapter(child: w)).toList();
  }

  Container _buildDragHandle() {
    return Container(
      // According to m3 spec https://m3.material.io/components/bottom-sheets/specs
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  BlocBuilder<LabelCubit<Tag>, LabelState<Tag>> _buildTagsFormField() {
    return BlocBuilder<LabelCubit<Tag>, LabelState<Tag>>(
      builder: (context, state) {
        return TagFormField(
          name: DocumentModel.tagsKey,
          initialValue: widget.initialFilter.tags,
          allowCreation: false,
          selectableOptions: state.labels,
        );
      },
    );
  }

  void _resetFilter() async {
    FocusScope.of(context).unfocus();
    Navigator.pop(
      context,
      DocumentFilter.initial.copyWith(
        sortField: widget.initialFilter.sortField,
        sortOrder: widget.initialFilter.sortOrder,
      ),
    );
  }

  Widget _buildDocumentTypeFormField() {
    return BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
      builder: (context, state) {
        return LabelFormField<DocumentType>(
          formBuilderState: _formKey.currentState,
          name: fkDocumentType,
          labelOptions: state.labels,
          textFieldLabel: S.of(context).documentDocumentTypePropertyLabel,
          initialValue: widget.initialFilter.documentType,
          prefixIcon: const Icon(Icons.description_outlined),
        );
      },
    );
  }

  Widget _buildCorrespondentFormField() {
    return BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>(
      builder: (context, state) {
        return LabelFormField<Correspondent>(
          formBuilderState: _formKey.currentState,
          name: fkCorrespondent,
          labelOptions: state.labels,
          textFieldLabel: S.of(context).documentCorrespondentPropertyLabel,
          initialValue: widget.initialFilter.correspondent,
          prefixIcon: const Icon(Icons.person_outline),
        );
      },
    );
  }

  Widget _buildStoragePathFormField() {
    return BlocBuilder<LabelCubit<StoragePath>, LabelState<StoragePath>>(
      builder: (context, state) {
        return LabelFormField<StoragePath>(
          formBuilderState: _formKey.currentState,
          name: fkStoragePath,
          labelOptions: state.labels,
          textFieldLabel: S.of(context).documentStoragePathPropertyLabel,
          initialValue: widget.initialFilter.storagePath,
          prefixIcon: const Icon(Icons.folder_outlined),
        );
      },
    );
  }

  Widget _buildQueryFormField() {
    return TextQueryFormField(
      name: fkQuery,
      onlyExtendedQueryAllowed: _allowOnlyExtendedQuery,
      initialValue: widget.initialFilter.query,
    );
  }

  void _onApplyFilter() async {
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      DocumentFilter newFilter = _assembleFilter();
      FocusScope.of(context).unfocus();
      Navigator.pop(context, newFilter);
    }
  }

  DocumentFilter _assembleFilter() {
    _formKey.currentState?.save();
    final v = _formKey.currentState!.value;
    return DocumentFilter(
      correspondent: v[fkCorrespondent] as IdQueryParameter? ??
          DocumentFilter.initial.correspondent,
      documentType: v[fkDocumentType] as IdQueryParameter? ??
          DocumentFilter.initial.documentType,
      storagePath: v[fkStoragePath] as IdQueryParameter? ??
          DocumentFilter.initial.storagePath,
      tags:
          v[DocumentModel.tagsKey] as TagsQuery? ?? DocumentFilter.initial.tags,
      query: v[fkQuery] as TextQuery? ?? DocumentFilter.initial.query,
      created: (v[fkCreatedAt] as DateRangeQuery),
      added: (v[fkAddedAt] as DateRangeQuery),
      asnQuery: widget.initialFilter.asnQuery,
      page: 1,
      pageSize: widget.initialFilter.pageSize,
      sortField: widget.initialFilter.sortField,
      sortOrder: widget.initialFilter.sortOrder,
    );
  }

  void _checkQueryConstraints() {
    final filter = _assembleFilter();
    if (filter.forceExtendedQuery) {
      setState(() => _allowOnlyExtendedQuery = true);
      final queryField = _formKey.currentState?.fields[fkQuery];
      queryField?.didChange(
        (queryField.value as TextQuery?)
            ?.copyWith(queryType: QueryType.extended),
      );
    } else {
      setState(() => _allowOnlyExtendedQuery = false);
    }
  }
}
