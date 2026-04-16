import 'dart:async';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/document_repository.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/pop_with_unsaved_changes.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/custom_field_form_field/form_builder_custom_fields_field.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/features/document_edit/view/custom_field_selection_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/document_view.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/single_label_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T itemData);

class DocumentEditPage extends StatefulWidget {
  final int documentId;
  const DocumentEditPage({super.key, required this.documentId});

  @override
  State<DocumentEditPage> createState() => _DocumentEditPageState();
}

class _DocumentEditPageState extends State<DocumentEditPage>
    with TickerProviderStateMixin {
  static const fkTitle = "title";
  static const fkCorrespondent = "correspondent";
  static const fkTags = "tags";
  static const fkDocumentType = "documentType";
  static const fkCreatedDate = "createdAtDate";
  static const fkStoragePath = 'storagePath';
  static const fkContent = 'content';
  static const fkCustomFields = 'customFields';

  final _formKey = GlobalKey<FormBuilderState>();

  bool _isShowingPdf = false;
  int _selectedTabIndex = 0;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiSettings = context.loggedInUser$.profile.uiSettings;
    return QueryBuilder(
      query: context.read<DocumentRepository>().getDocumentQuery(
        widget.documentId,
      ),
      builder: (context, state) {
        if (state.isError) {
          //TODO: error handling
          return SizedBox.shrink();
        }
        if (state.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return PopWithUnsavedChanges(
          hasChangesPredicate: () {
            final fkState = _formKey.currentState;
            if (fkState == null) {
              return false;
            }
            final doc = state.data!;
            final (
              :title,
              :correspondent,
              :documentType,
              :storagePath,
              :tags,
              :createdAt,
              :content,
              :customFields,
            ) = _currentValues;
            final isContentTouched =
                _formKey.currentState?.fields[fkContent]?.isDirty ?? false;
            return doc.title != title ||
                doc.correspondent != correspondent ||
                doc.documentType != documentType ||
                doc.storagePath != storagePath ||
                !const UnorderedIterableEquality().equals(doc.tags, tags) ||
                doc.created != createdAt ||
                (doc.content != content && isContentTouched) ||
                !const ListEquality<CustomFieldInstance>().equals(
                  doc.customFields ?? [],
                  customFields,
                );
          },
          child: FormBuilder(
            key: _formKey,
            initialValue: {
              fkTitle: state.data!.title,
              fkCorrespondent: state.data!.correspondent,
              fkDocumentType: state.data!.documentType,
              fkStoragePath: state.data!.storagePath,
              fkTags: IdsTagsQuery(include: state.data!.tags ?? []),
              fkCreatedDate: state.data!.created,
              fkContent: state.data!.content,
              fkCustomFields:
                  state.data!.customFields ?? <CustomFieldInstance>[],
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(S.of(context)!.editDocument),
                actions: [
                  IconButton(
                    tooltip: _isShowingPdf
                        ? S.of(context)!.hidePdf
                        : S.of(context)!.showPdf,
                    padding: EdgeInsets.all(12),
                    icon: Icon(
                      _isShowingPdf
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _isShowingPdf = !_isShowingPdf;
                      });
                    },
                  ).paddedOnly(right: 8),
                ],
              ),
              body: Stack(
                children: [
                  Scaffold(
                    resizeToAvoidBottomInset: true,
                    floatingActionButton: !_isShowingPdf
                        ? FloatingActionButton.extended(
                            heroTag: "fab_document_edit",
                            onPressed: () => _onSubmit(state.data!),
                            icon: const Icon(Icons.save),
                            label: Text(S.of(context)!.saveChanges),
                          )
                        : null,
                    appBar: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: S.of(context)!.overview),
                        Tab(text: S.of(context)!.content),
                      ],
                    ),
                    extendBody: true,
                    body: QueryBuilder(
                      query: context
                          .read<DocumentRepository>()
                          .getFieldSuggestionsQuery(state.data!.id),
                      builder: (context, suggestionsState) {
                        return _buildEditForm(
                          context,
                          state.data!,
                          suggestionsState.data,
                          uiSettings,
                        );
                      },
                    ),
                  ),
                  QueryBuilder(
                    query: context
                        .read<DocumentRepository>()
                        .downloadDocumentQuery(
                          widget.documentId,
                          original: true,
                        ),
                    builder: (context, downloadState) {
                      if (downloadState.isLoading) {
                        return SizedBox.shrink();
                      }
                      return Visibility(
                        visible: _isShowingPdf,
                        child:
                            DocumentView(
                              documentId: widget.documentId,
                              title: state.data?.title,
                              mimeType:
                                  state.data?.mimeType ?? 'application/pdf',
                              showAppBar: false,
                              showControls: false,
                            ).animate().fadeIn(
                              duration: const Duration(milliseconds: 100),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    Document document,
    Suggestions? fieldSuggestions,
    UiSettingsView uiSettings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IndexedStack(
        index: _selectedTabIndex,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              child: Column(
                children:
                    [
                          SizedBox(height: 16),
                          _buildTitleFormField(document.title),
                          _buildCreatedAtFormField(
                            document.created,
                            fieldSuggestions,
                          ),
                          // Correspondent form field
                          if (uiSettings.canViewCorrespondents)
                            SingleLabelFormField<Correspondent>(
                              onAddLabel: uiSettings.canCreateCorrespondents
                                  ? (currentInput) => CreateLabelRoute(
                                      LabelType.correspondent,
                                      name: currentInput,
                                    ).push<Correspondent>(context)
                                  : null,
                              addLabelText: uiSettings.canCreateCorrespondents
                                  ? S.of(context)!.addCorrespondent
                                  : null,
                              labelText: S.of(context)!.correspondent,
                              query: context.correspondentRepository
                                  .getAllQuery(),
                              initialValue: document.correspondent,
                              name: fkCorrespondent,
                              prefixIcon: const Icon(Icons.person_outlined),
                              suggestions:
                                  fieldSuggestions?.correspondents ?? [],
                            ),
                          // DocumentType form field
                          if (uiSettings.canViewDocumentTypes)
                            SingleLabelFormField<DocumentType>(
                              onAddLabel: uiSettings.canCreateDocumentTypes
                                  ? (currentInput) => CreateLabelRoute(
                                      LabelType.documentType,
                                      name: currentInput,
                                    ).push<DocumentType>(context)
                                  : null,
                              addLabelText: uiSettings.canCreateDocumentTypes
                                  ? S.of(context)!.addDocumentType
                                  : null,
                              labelText: S.of(context)!.documentType,
                              initialValue: document.documentType,
                              query: context.documentTypeRepository
                                  .getAllQuery(),
                              name: _DocumentEditPageState.fkDocumentType,
                              prefixIcon: const Icon(
                                Icons.description_outlined,
                              ),
                              suggestions:
                                  fieldSuggestions?.documentTypes ?? [],
                            ),
                          // StoragePath form field
                          if (uiSettings.canViewStoragePaths)
                            SingleLabelFormField<StoragePath>(
                              onAddLabel: uiSettings.canCreateStoragePaths
                                  ? (currentInput) => CreateLabelRoute(
                                      LabelType.storagePath,
                                      name: currentInput,
                                    ).push<StoragePath>(context)
                                  : null,
                              addLabelText: uiSettings.canCreateStoragePaths
                                  ? S.of(context)!.addStoragePath
                                  : null,
                              labelText: S.of(context)!.storagePath,
                              query: context.storagePathRepository
                                  .getAllQuery(),
                              initialValue: document.storagePath,
                              name: fkStoragePath,
                              prefixIcon: const Icon(Icons.folder_outlined),
                            ),
                          // Tag form field
                          if (uiSettings.canViewTags)
                            TagsFormField(
                              name: fkTags,
                              allowCreation: true,
                              allowExclude: false,
                              suggestions:
                                  fieldSuggestions?.tags.toSet().difference(
                                    document.tags?.toSet() ?? {},
                                  ) ??
                                  {},
                              initialValue: IdsTagsQuery(
                                include: document.tags ?? [],
                              ),
                            ),
                          SizedBox(height: 24),
                          // Custom fields
                          if (context.uiSettings$.canViewCustomFields)
                            FormBuilderCustomFieldsField(
                              parentDocumentId: document.id,
                              name: fkCustomFields,
                              initialValue: document.customFields ?? [],
                            ),
                          _buildAddCustomFieldToDocumentButton(
                            context,
                          ).paddedOnly(top: 16),
                          const SizedBox(height: 140),
                        ]
                        .expand((child) => [child, const SizedBox(height: 16)])
                        .toList(),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                FormBuilderTextField(
                  name: fkContent,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  initialValue: document.content,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                const SizedBox(height: 84),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomFieldToDocumentButton(BuildContext context) {
    return FilledButton.tonalIcon(
      label: Text(S.of(context)!.addCustomFieldToDocument),
      icon: Icon(Icons.tune),
      onPressed: () async {
        final currentInstances =
            _formKey.currentState?.fields[fkCustomFields]?.value
                as List<CustomFieldInstance>? ??
            [];
        final excludeFieldIds = currentInstances.map((e) => e.field).toList();
        final selectedField = await Navigator.of(context).push<CustomField?>(
          MaterialPageRoute(
            builder: (context) =>
                CustomFieldSelectionPage(excludeFieldIds: excludeFieldIds),
          ),
        );
        if (selectedField != null) {
          final updated = [
            ...currentInstances,
            CustomFieldInstance(field: selectedField.id, value: null),
          ];
          _formKey.currentState?.fields[fkCustomFields]?.didChange(updated);
        }
      },
    );
  }

  ({
    String? title,
    int? correspondent,
    int? documentType,
    int? storagePath,
    List<int>? tags,
    DateTime? createdAt,
    String? content,
    List<CustomFieldInstance> customFields,
  })
  get _currentValues {
    final fkState = _formKey.currentState!.fields;

    final correspondent = fkState[fkCorrespondent]?.value as int?;
    final documentType = fkState[fkDocumentType]?.value as int?;
    final storagePath = fkState[fkStoragePath]?.value as int?;
    final tagsParam = fkState[fkTags]?.value as IdsTagsQuery?;
    final title = fkState[fkTitle]?.value as String?;
    final created = fkState[fkCreatedDate]?.value as FormDateTime?;
    final tags = switch (tagsParam) {
      IdsTagsQuery(include: var include) => include,
      _ => null,
    };
    final content = fkState[fkContent]?.value as String?;
    final customFields =
        fkState[fkCustomFields]?.value as List<CustomFieldInstance>? ?? [];

    return (
      title: title,
      correspondent: correspondent,
      documentType: documentType,
      storagePath: storagePath,
      tags: tags,
      createdAt: created?.toDateTime(),
      content: content,
      customFields: customFields,
    );
  }

  Future<void> _onSubmit(Document document) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final (
        :title,
        :correspondent,
        :documentType,
        :storagePath,
        :tags,
        :createdAt,
        :content,
        :customFields,
      ) = _currentValues;

      final customFieldRequests = customFields
          .map(
            (i) => CustomFieldInstanceRequest(field: i.field, value: i.value),
          )
          .toList();

      try {
        var request = PatchedDocumentRequest(
          correspondent: PatchedValue(correspondent),
          documentType: PatchedValue(documentType),
          storagePath: PatchedValue(storagePath),
          tags: PatchedValue(tags),
          content: PatchedValue(content),
          title: PatchedValue(title),
          created: PatchedValue(createdAt),
          customFields: PatchedValue(customFieldRequests),
        );
        final result = await context
            .read<DocumentRepository>()
            .patchDocumentMutation(document.id)
            .mutate(request);
        if (result is MutationError) {
          throw (result as MutationError).error;
        }
        if (mounted) {
          showSnackBar(context, S.of(context)!.documentSuccessfullyUpdated);
          context.pop();
        }
      } on PaperlessApiException catch (error, stackTrace) {
        if (mounted) showErrorMessage(context, error, stackTrace);
      } catch (error, stackTrace) {
        if (mounted) showGenericError(context, error, stackTrace);
      }
    }
  }

  Widget _buildTitleFormField(String? initialTitle) {
    return FormBuilderTextField(
      name: fkTitle,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        label: Text(S.of(context)!.title),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            _formKey.currentState?.fields[fkTitle]?.didChange(null);
          },
        ),
      ),
      initialValue: initialTitle,
    );
  }

  Widget _buildCreatedAtFormField(
    DateTime? initialCreatedAtDate,
    Suggestions? filteredSuggestions,
  ) {
    final hasSuggestedDates = filteredSuggestions?.dates.isNotEmpty ?? false;
    return Column(
      children: [
        FormBuilderLocalizedDatePicker(
          name: fkCreatedDate,
          initialValue: initialCreatedAtDate,
          labelText: S.of(context)!.createdAt,
          firstDate: DateTime(1000, 1, 1),
          lastDate: DateTime(9999, 12, 31),
          prefixIcon: Icon(Icons.calendar_today),
          allowUnset: false,
        ),
        if (hasSuggestedDates)
          _buildSuggestionsSkeleton<DateTime>(
            suggestions: filteredSuggestions!.dates.map(DateTime.parse),
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(context.displayDateFormat.format(itemData)),
              onPressed: () => _formKey.currentState?.fields[fkCreatedDate]
                  ?.didChange(FormDateTime.fromDateTime(itemData)),
            ),
          ),
      ],
    );
  }

  ///
  /// Item builder is typically some sort of [Chip].
  ///
  Widget _buildSuggestionsSkeleton<T>({
    required Iterable<T> suggestions,
    required ItemBuilder<T> itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.suggestions,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, suggestions.elementAt(index)),
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 4.0),
          ),
        ),
      ],
    ).padded();
  }
}
