import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/user_repository.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/extended_date_range_form_field/form_builder_extended_date_range_picker.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/owner_form_field.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/custom_field_filter_section.dart';

import 'text_query_form_field.dart';

class DocumentFilterForm extends StatefulWidget {
  static const fkCorrespondent = DocumentModel.correspondentKey;
  static const fkDocumentType = DocumentModel.documentTypeKey;
  static const fkStoragePath = DocumentModel.storagePathKey;
  static const fkQuery = "query";
  static const fkOwner = "owner";
  static const fkCustomFields = "customFields";
  static const fkCreatedAt = DocumentModel.createdKey;
  static const fkAddedAt = DocumentModel.addedKey;

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
      documentType: v[DocumentFilterForm.fkDocumentType] as IdQueryParameter? ??
          DocumentFilter.initial.documentType,
      storagePath: v[DocumentFilterForm.fkStoragePath] as IdQueryParameter? ??
          DocumentFilter.initial.storagePath,
      tags:
          v[DocumentModel.tagsKey] as TagsQuery? ?? DocumentFilter.initial.tags,
      owner: v[DocumentFilterForm.fkOwner] as IdQueryParameter? ??
          DocumentFilter.initial.owner,
      query: v[DocumentFilterForm.fkQuery] as TextQuery? ??
          DocumentFilter.initial.query,
      created: (v[DocumentFilterForm.fkCreatedAt] as DateRangeQuery),
      added: (v[DocumentFilterForm.fkAddedAt] as DateRangeQuery),
      customFieldQueries:
          v[DocumentFilterForm.fkCustomFields] as List<CustomFieldQueryClause>?,
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
    final labelRepository = context.watch<LabelRepository>();
    return FormBuilder(
      key: widget.formKey,
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          if (widget.header != null) widget.header!,
          ..._buildFormFieldList(labelRepository),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 32,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormFieldList(LabelRepository labelRepository) {
    final hasMultiUserSupport =
        context.watch<LocalUserAccount>().hasMultiUserSupport;
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
      _buildCorrespondentFormField(labelRepository.correspondents)
          .paddedSymmetrically(
        horizontal: 16,
        vertical: 4,
      ),
      _buildDocumentTypeFormField(labelRepository.documentTypes)
          .paddedSymmetrically(
        horizontal: 16,
        vertical: 4,
      ),
      _buildStoragePathFormField(labelRepository.storagePaths)
          .paddedSymmetrically(
        horizontal: 16,
        vertical: 4,
      ),
      _buildTagsFormField(labelRepository.tags).paddedSymmetrically(
        horizontal: 16,
        vertical: 4,
      ),
      if (hasMultiUserSupport)
        _buildOwnerFormField().paddedSymmetrically(
          horizontal: 16,
          vertical: 4,
        ),
      CustomFieldFilterSection(
        name: DocumentFilterForm.fkCustomFields,
        initialClauses: widget.initialFilter.customFieldQueries,
      ).paddedSymmetrically(
        horizontal: 16,
        vertical: 4,
      ),
    ].map((e) => SliverToBoxAdapter(child: e)).toList();
  }

  void _checkQueryConstraints() {
    final filter =
        DocumentFilterForm.assembleFilter(widget.formKey, widget.initialFilter);
    if (filter.forceExtendedQuery) {
      setState(() => _allowOnlyExtendedQuery = true);
      final queryField =
          widget.formKey.currentState?.fields[DocumentFilterForm.fkQuery];
      queryField?.didChange(
        (queryField.value as TextQuery?)
            ?.copyWith(queryType: QueryType.extended),
      );
    } else {
      setState(() => _allowOnlyExtendedQuery = false);
    }
  }

  Widget _buildDocumentTypeFormField(Map<int, DocumentType> documentTypes) {
    return LabelFormField<DocumentType>(
      name: DocumentFilterForm.fkDocumentType,
      options: documentTypes,
      labelText: S.of(context)!.documentType,
      initialValue: widget.initialFilter.documentType,
      prefixIcon: const Icon(Icons.description_outlined),
      allowSelectUnassigned: false,
      canCreateNewLabel: context
          .watch<LocalUserAccount>()
          .paperlessUser
          .canCreateDocumentTypes,
    );
  }

  Widget _buildCorrespondentFormField(Map<int, Correspondent> correspondents) {
    return LabelFormField<Correspondent>(
      name: DocumentFilterForm.fkCorrespondent,
      options: correspondents,
      labelText: S.of(context)!.correspondent,
      initialValue: widget.initialFilter.correspondent,
      prefixIcon: const Icon(Icons.person_outline),
      allowSelectUnassigned: false,
      canCreateNewLabel: context
          .watch<LocalUserAccount>()
          .paperlessUser
          .canCreateCorrespondents,
    );
  }

  Widget _buildStoragePathFormField(Map<int, StoragePath> storagePaths) {
    return LabelFormField<StoragePath>(
      name: DocumentFilterForm.fkStoragePath,
      options: storagePaths,
      labelText: S.of(context)!.storagePath,
      initialValue: widget.initialFilter.storagePath,
      prefixIcon: const Icon(Icons.folder_outlined),
      allowSelectUnassigned: false,
      canCreateNewLabel:
          context.watch<LocalUserAccount>().paperlessUser.canCreateStoragePaths,
    );
  }

  Widget _buildQueryFormField() {
    return TextQueryFormField(
      name: DocumentFilterForm.fkQuery,
      onlyExtendedQueryAllowed: _allowOnlyExtendedQuery,
      initialValue: widget.initialFilter.query,
    );
  }

  Widget _buildOwnerFormField() {
    return BlocBuilder<UserRepository, UserRepositoryState>(
      builder: (context, state) {
        return OwnerFormField(
          name: DocumentFilterForm.fkOwner,
          users: state.users,
          initialValue: widget.initialFilter.owner,
        );
      },
    );
  }

  Widget _buildTagsFormField(Map<int, Tag> tags) {
    return TagsFormField(
      name: DocumentModel.tagsKey,
      initialValue: widget.initialFilter.tags,
      options: tags,
      allowExclude: false,
      allowOnlySelection: false,
      allowCreation: false,
    );
  }
}
