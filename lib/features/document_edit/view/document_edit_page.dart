import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/pop_with_unsaved_changes.dart';
import 'package:paperless_mobile/core/widgets/form_builder_fields/form_builder_localized_date_picker.dart';
import 'package:paperless_mobile/core/widgets/colored_chip.dart';
import 'package:paperless_mobile/features/document_edit/cubit/document_edit_cubit.dart';
import 'package:paperless_mobile/core/widgets/document_view.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/labels_route.dart';

typedef ItemBuilder<T> = Widget Function(BuildContext context, T itemData);

class DocumentEditPage extends StatefulWidget {
  const DocumentEditPage({super.key});

  @override
  State<DocumentEditPage> createState() => _DocumentEditPageState();
}

class _DocumentEditPageState extends State<DocumentEditPage>
    with SingleTickerProviderStateMixin {
  static const fkTitle = "title";
  static const fkCorrespondent = "correspondent";
  static const fkTags = "tags";
  static const fkDocumentType = "documentType";
  static const fkCreatedDate = "createdAtDate";
  static const fkStoragePath = 'storagePath';
  static const fkContent = 'content';

  final _formKey = GlobalKey<FormBuilderState>();

  bool _isShowingPdf = false;

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInCubic)
            .drive(Tween<double>(begin: 0, end: 1));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LocalUserAccount>().paperlessUser;
    return BlocBuilder<DocumentEditCubit, DocumentEditState>(
      builder: (context, state) {
        final filteredSuggestions = state.suggestions;
        return PopWithUnsavedChanges(
          hasChangesPredicate: () {
            final fkState = _formKey.currentState;
            if (fkState == null) {
              return false;
            }
            final doc = state.document;
            final (
              title,
              correspondent,
              documentType,
              storagePath,
              tags,
              createdAt,
              content
            ) = _currentValues;
            final isContentTouched =
                _formKey.currentState?.fields[fkContent]?.isDirty ?? false;
            return doc.title != title ||
                doc.correspondent != correspondent ||
                doc.documentType != documentType ||
                doc.storagePath != storagePath ||
                !const UnorderedIterableEquality().equals(doc.tags, tags) ||
                doc.created != createdAt ||
                (doc.content != content && isContentTouched);
          },
          child: FormBuilder(
            key: _formKey,
            child: Scaffold(
              appBar: AppBar(
                title: Text(S.of(context)!.editDocument),
                actions: [
                  IconButton(
                    tooltip: _isShowingPdf
                        ? S.of(context)!.hidePdf
                        : S.of(context)!.showPdf,
                    padding: EdgeInsets.all(12),
                    icon: AnimatedCrossFade(
                      duration: _animationController.duration!,
                      reverseDuration: _animationController.reverseDuration,
                      crossFadeState: _isShowingPdf
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Icon(Icons.visibility_off_outlined),
                      secondChild: Icon(Icons.visibility_outlined),
                    ),
                    onPressed: () {
                      if (_isShowingPdf) {
                        setState(() {
                          _isShowingPdf = false;
                        });
                        _animationController.reverse();
                      } else {
                        setState(() {
                          _isShowingPdf = true;
                        });
                        _animationController.forward();
                      }
                    },
                  )
                ],
              ),
              body: Stack(
                children: [
                  DefaultTabController(
                    length: 2,
                    child: Scaffold(
                      resizeToAvoidBottomInset: true,
                      floatingActionButton: !_isShowingPdf
                          ? FloatingActionButton.extended(
                              heroTag: "fab_document_edit",
                              onPressed: () => _onSubmit(state.document),
                              icon: const Icon(Icons.save),
                              label: Text(S.of(context)!.saveChanges),
                            )
                          : null,
                      appBar: TabBar(
                        tabs: [
                          Tab(text: S.of(context)!.overview),
                          Tab(text: S.of(context)!.content),
                        ],
                      ),
                      extendBody: true,
                      body: _buildEditForm(
                        context,
                        state,
                        filteredSuggestions,
                        currentUser,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        alignment: Alignment.bottomLeft,
                        scale: _animation.value,
                        child: DocumentView(
                          showAppBar: false,
                          showControls: false,
                          title: state.document.title,
                          bytes: context
                              .read<PaperlessDocumentsApi>()
                              .downloadDocument(state.document.id),
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

  Padding _buildEditForm(
    BuildContext context,
    DocumentEditState state,
    FieldSuggestions? filteredSuggestions,
    UserModel currentUser,
  ) {
    final labelRepository = context.watch<LabelRepository>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        children: [
          ListView(
            children: [
              SizedBox(height: 16),
              _buildTitleFormField(state.document.title).padded(),
              _buildCreatedAtFormField(
                state.document.created,
                filteredSuggestions,
              ).padded(),
              // Correspondent form field
              if (currentUser.canViewCorrespondents)
                Column(
                  children: [
                    LabelFormField<Correspondent>(
                      showAnyAssignedOption: false,
                      showNotAssignedOption: false,
                      onAddLabel: (currentInput) => CreateLabelRoute(
                        LabelType.correspondent,
                        name: currentInput,
                      ).push<Correspondent>(context),
                      addLabelText: S.of(context)!.addCorrespondent,
                      labelText: S.of(context)!.correspondent,
                      options: labelRepository.correspondents,
                      initialValue: state.document.correspondent != null
                          ? SetIdQueryParameter(
                              id: state.document.correspondent!)
                          : const UnsetIdQueryParameter(),
                      name: fkCorrespondent,
                      prefixIcon: const Icon(Icons.person_outlined),
                      allowSelectUnassigned: true,
                      canCreateNewLabel: currentUser.canCreateCorrespondents,
                      suggestions: filteredSuggestions?.correspondents ?? [],
                    ),
                  ],
                ).padded(),
              // DocumentType form field
              if (currentUser.canViewDocumentTypes)
                Column(
                  children: [
                    LabelFormField<DocumentType>(
                      showAnyAssignedOption: false,
                      showNotAssignedOption: false,
                      onAddLabel: (currentInput) => CreateLabelRoute(
                        LabelType.documentType,
                        name: currentInput,
                      ).push<DocumentType>(context),
                      canCreateNewLabel: currentUser.canCreateDocumentTypes,
                      addLabelText: S.of(context)!.addDocumentType,
                      labelText: S.of(context)!.documentType,
                      initialValue: state.document.documentType != null
                          ? SetIdQueryParameter(
                              id: state.document.documentType!)
                          : const UnsetIdQueryParameter(),
                      options: labelRepository.documentTypes,
                      name: _DocumentEditPageState.fkDocumentType,
                      prefixIcon: const Icon(Icons.description_outlined),
                      allowSelectUnassigned: true,
                      suggestions: filteredSuggestions?.documentTypes ?? [],
                    ),
                  ],
                ).padded(),
              // StoragePath form field
              if (currentUser.canViewStoragePaths)
                Column(
                  children: [
                    LabelFormField<StoragePath>(
                      showAnyAssignedOption: false,
                      showNotAssignedOption: false,
                      onAddLabel: (currentInput) => CreateLabelRoute(
                        LabelType.storagePath,
                        name: currentInput,
                      ).push<StoragePath>(context),
                      canCreateNewLabel: currentUser.canCreateStoragePaths,
                      addLabelText: S.of(context)!.addStoragePath,
                      labelText: S.of(context)!.storagePath,
                      options: labelRepository.storagePaths,
                      initialValue: state.document.storagePath != null
                          ? SetIdQueryParameter(id: state.document.storagePath!)
                          : const UnsetIdQueryParameter(),
                      name: fkStoragePath,
                      prefixIcon: const Icon(Icons.folder_outlined),
                      allowSelectUnassigned: true,
                    ),
                  ],
                ).padded(),
              // Tag form field
              if (currentUser.canViewTags)
                TagsFormField(
                  options: labelRepository.tags,
                  name: fkTags,
                  allowOnlySelection: true,
                  allowCreation: true,
                  allowExclude: false,
                  suggestions: filteredSuggestions?.tags ?? [],
                  initialValue: IdsTagsQuery(
                    include: state.document.tags.toList(),
                  ),
                ).padded(),

              const SizedBox(height: 140),
            ],
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                FormBuilderTextField(
                  name: fkContent,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  initialValue: state.document.content,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 84),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (
    String? title,
    int? correspondent,
    int? documentType,
    int? storagePath,
    List<int>? tags,
    DateTime? createdAt,
    String? content,
  ) get _currentValues {
    final fkState = _formKey.currentState!;

    final correspondentParam =
        fkState.getRawValue<IdQueryParameter?>(fkCorrespondent);
    final documentTypeParam =
        fkState.getRawValue<IdQueryParameter?>(fkDocumentType);
    final storagePathParam =
        fkState.getRawValue<IdQueryParameter?>(fkStoragePath);
    final tagsParam = fkState.getRawValue<TagsQuery?>(fkTags);
    final title = fkState.getRawValue<String?>(fkTitle);
    final created = fkState.getRawValue<FormDateTime?>(fkCreatedDate);
    final correspondent = switch (correspondentParam) {
      SetIdQueryParameter(id: var id) => id,
      _ => null,
    };
    final documentType = switch (documentTypeParam) {
      SetIdQueryParameter(id: var id) => id,
      _ => null,
    };
    final storagePath = switch (storagePathParam) {
      SetIdQueryParameter(id: var id) => id,
      _ => null,
    };
    final tags = switch (tagsParam) {
      IdsTagsQuery(include: var i) => i,
      _ => null,
    };
    final content = fkState.getRawValue<String?>(fkContent);

    return (
      title,
      correspondent,
      documentType,
      storagePath,
      tags,
      created?.toDateTime(),
      content
    );
  }

  Future<void> _onSubmit(DocumentModel document) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final (
        title,
        correspondent,
        documentType,
        storagePath,
        tags,
        createdAt,
        content
      ) = _currentValues;
      var mergedDocument = document.copyWith(
        title: title,
        created: createdAt,
        correspondent: () => correspondent,
        documentType: () => documentType,
        storagePath: () => storagePath,
        tags: tags,
        content: content,
      );

      try {
        await context.read<DocumentEditCubit>().updateDocument(mergedDocument);
        if (mounted) {
          showSnackBar(context, S.of(context)!.documentSuccessfullyUpdated);
        }
      } on PaperlessApiException catch (error, stackTrace) {
        if (mounted) showErrorMessage(context, error, stackTrace);
      } finally {
        if (mounted) context.pop();
      }
    }
  }

  Widget _buildTitleFormField(String? initialTitle) {
    return FormBuilderTextField(
      name: fkTitle,
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
      DateTime? initialCreatedAtDate, FieldSuggestions? filteredSuggestions) {
    return Column(
      children: [
        FormBuilderLocalizedDatePicker(
          name: fkCreatedDate,
          initialValue: initialCreatedAtDate,
          labelText: S.of(context)!.createdAt,
          firstDate: DateTime(1970, 1, 1),
          lastDate: DateTime(2100, 1, 1),
          locale: Localizations.localeOf(context),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        if (filteredSuggestions?.hasSuggestedDates ?? false)
          _buildSuggestionsSkeleton<DateTime>(
            suggestions: filteredSuggestions!.dates,
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(
                  DateFormat.yMMMMd(Localizations.localeOf(context).toString())
                      .format(itemData)),
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
            itemBuilder: (context, index) => ColoredChipWrapper(
              child: itemBuilder(context, suggestions.elementAt(index)),
            ),
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 4.0),
          ),
        ),
      ],
    ).padded();
  }
}
