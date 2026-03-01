import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/form_builder_extended_date_range_picker.dart';
import 'package:paperless_mobile/core/widgets/query_builder/label_query_builder.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/multi_label_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

import 'text_query_form_field.dart';

class DocumentFilterForm extends StatefulWidget {
  static const fkCorrespondent = "correspondent";
  static const fkDocumentType = "documentType";
  static const fkStoragePath = "storagePath";
  static const fkTags = "tags";
  static const fkQuery = "query";
  static const fkCreatedAt = "createdAt";
  static const fkAddedAt = "addedAt";

  static DocumentFilter assembleFilter(
    GlobalKey<FormBuilderState> formKey,
    DocumentFilter initialFilter,
  ) {
    formKey.currentState?.save();
    final v = formKey.currentState!.value;
    return initialFilter.copyWith(
      correspondent:
          v[DocumentFilterForm.fkCorrespondent] as IdQueryParameter? ??
          DocumentFilter.initial.correspondent,
      documentType:
          v[DocumentFilterForm.fkDocumentType] as IdQueryParameter? ??
          DocumentFilter.initial.documentType,
      storagePath:
          v[DocumentFilterForm.fkStoragePath] as IdQueryParameter? ??
          DocumentFilter.initial.storagePath,
      tags: v['tags'] as TagsQuery? ?? DocumentFilter.initial.tags,
      query:
          v[DocumentFilterForm.fkQuery] as TextQuery? ??
          DocumentFilter.initial.query,
      created: (v[DocumentFilterForm.fkCreatedAt] as DateRangeQuery?) ??
          const UnsetDateRangeQuery(),
      added: (v[DocumentFilterForm.fkAddedAt] as DateRangeQuery?) ??
          const UnsetDateRangeQuery(),
      page: 1,
    );
  }

  final Widget? header;
  final GlobalKey<FormBuilderState> formKey;
  final DocumentFilter initialFilter;
  final ScrollController? scrollController;
  final EdgeInsets padding;

  const DocumentFilterForm({
    super.key,
    this.header,
    required this.formKey,
    required this.initialFilter,
    this.scrollController,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  });

  @override
  State<DocumentFilterForm> createState() => _DocumentFilterFormState();
}

class _DocumentFilterFormState extends State<DocumentFilterForm> {
  late bool _allowOnlyExtendedQuery;

  @override
  void initState() {
    super.initState();
    _allowOnlyExtendedQuery = widget.initialFilter.forceExtendedQuery;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: widget.formKey,
      child: LabelQueryBuilder(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isError) {
            return Center(child: Text(S.of(context)!.anUnknownErrorOccurred));
          }

          final data = state.data!;
          return CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              if (widget.header != null) widget.header!,
              SliverToBoxAdapter(child: SizedBox(height: 8)),
              ..._buildFormFieldList(data),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildFormFieldList(LabelBuilderData data) {
    return [
      _buildQueryFormField().paddedSymmetrically(horizontal: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          S.of(context)!.advanced,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ).paddedLTRB(12, 16, 12, 0),
      FormBuilderExtendedDateRangePicker(
        name: DocumentFilterForm.fkCreatedAt,
        initialValue: widget.initialFilter.created,
        labelText: S.of(context)!.createdAt,
        onChanged: (_) {
          _checkQueryConstraints();
        },
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      FormBuilderExtendedDateRangePicker(
        name: DocumentFilterForm.fkAddedAt,
        initialValue: widget.initialFilter.added,
        labelText: S.of(context)!.addedAt,
        onChanged: (_) {
          _checkQueryConstraints();
        },
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      _buildCorrespondentFormField(
        data.correspondents,
      ).paddedSymmetrically(horizontal: 16, vertical: 4),
      _buildDocumentTypeFormField(
        data.documentTypes,
      ).paddedSymmetrically(horizontal: 16, vertical: 4),
      _buildStoragePathFormField(
        data.storagePaths,
      ).paddedSymmetrically(horizontal: 16, vertical: 4),
      _buildTagsFormField(
        data.tags,
      ).paddedSymmetrically(horizontal: 16, vertical: 4),
    ].map((e) => SliverToBoxAdapter(child: e)).toList();
  }

  void _checkQueryConstraints() {
    final filter = DocumentFilterForm.assembleFilter(
      widget.formKey,
      widget.initialFilter,
    );
    if (filter.forceExtendedQuery) {
      setState(() => _allowOnlyExtendedQuery = true);
      final queryField =
          widget.formKey.currentState?.fields[DocumentFilterForm.fkQuery];
      queryField?.didChange(
        (queryField.value as TextQuery?)?.copyWith(
          queryType: QueryType.extended,
        ),
      );
    } else {
      setState(() => _allowOnlyExtendedQuery = false);
    }
  }

  Widget _buildDocumentTypeFormField(Map<int, DocumentType> documentTypes) {
    return MultiLabelFormField<DocumentType>(
      name: DocumentFilterForm.fkDocumentType,
      query: context.documentTypeRepository.getAllQuery(),
      labelText: S.of(context)!.documentType,
      initialValue: widget.initialFilter.documentType,
      prefixIcon: const Icon(Icons.description_outlined),
      allowExclude: true,
    );
  }

  Widget _buildCorrespondentFormField(Map<int, Correspondent> correspondents) {
    return MultiLabelFormField<Correspondent>(
      name: DocumentFilterForm.fkCorrespondent,
      query: context.correspondentRepository.getAllQuery(),
      labelText: S.of(context)!.correspondent,
      initialValue: widget.initialFilter.correspondent,
      prefixIcon: const Icon(Icons.person_outline),
      allowExclude: true,
    );
  }

  Widget _buildStoragePathFormField(Map<int, StoragePath> storagePaths) {
    return MultiLabelFormField<StoragePath>(
      name: DocumentFilterForm.fkStoragePath,
      query: context.storagePathRepository.getAllQuery(),
      labelText: S.of(context)!.storagePath,
      initialValue: widget.initialFilter.storagePath,
      prefixIcon: const Icon(Icons.folder_outlined),
      allowExclude: true,
    );
  }

  Widget _buildQueryFormField() {
    return TextQueryFormField(
      name: DocumentFilterForm.fkQuery,
      onlyExtendedQueryAllowed: _allowOnlyExtendedQuery,
      initialValue: widget.initialFilter.query,
    );
  }

  Widget _buildTagsFormField(Map<int, Tag> tags) {
    return TagsFormField(
      name: DocumentFilterForm.fkTags,
      initialValue: widget.initialFilter.tags,
      allowExclude: true,
      allowCreation: false,
    );
  }
}
