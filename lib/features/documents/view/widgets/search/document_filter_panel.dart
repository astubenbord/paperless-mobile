import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/query_type_form_field.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';

enum DateRangeSelection { before, after }

class DocumentFilterPanel extends StatefulWidget {
  final DocumentFilter initialFilter;
  final ScrollController scrollController;
  const DocumentFilterPanel({
    Key? key,
    required this.initialFilter,
    required this.scrollController,
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
              )
            ],
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: FormBuilder(
          key: _formKey,
          child: ListView(
            controller: widget.scrollController,
            children: [
              Text(
                S.of(context).documentFilterTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ).paddedOnly(
                top: 16.0,
                left: 16.0,
                bottom: 24,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.of(context).documentFilterSearchLabel,
                  style: Theme.of(context).textTheme.caption,
                ),
              ).paddedOnly(left: 8.0),
              _buildQueryFormField().padded(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  S.of(context).documentFilterAdvancedLabel,
                  style: Theme.of(context).textTheme.caption,
                ),
              ).padded(),
              _buildCreatedDateRangePickerFormField(),
              _buildAddedDateRangePickerFormField(),
              _buildCorrespondentFormField().padded(),
              _buildDocumentTypeFormField().padded(),
              _buildStoragePathFormField().padded(),
              _buildTagsFormField().padded(),
            ],
          ).paddedOnly(bottom: 16),
        ),
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
    Navigator.pop(context, DocumentFilter.initial);
  }

  Widget _buildDocumentTypeFormField() {
    return BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
      builder: (context, state) {
        return LabelFormField<DocumentType, DocumentTypeQuery>(
          formBuilderState: _formKey.currentState,
          name: fkDocumentType,
          state: state.labels,
          label: S.of(context).documentDocumentTypePropertyLabel,
          initialValue: widget.initialFilter.documentType,
          queryParameterIdBuilder: DocumentTypeQuery.fromId,
          queryParameterNotAssignedBuilder: DocumentTypeQuery.notAssigned,
          prefixIcon: const Icon(Icons.description_outlined),
        );
      },
    );
  }

  Widget _buildCorrespondentFormField() {
    return BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>(
      builder: (context, state) {
        return LabelFormField<Correspondent, CorrespondentQuery>(
          formBuilderState: _formKey.currentState,
          name: fkCorrespondent,
          state: state.labels,
          label: S.of(context).documentCorrespondentPropertyLabel,
          initialValue: widget.initialFilter.correspondent,
          queryParameterIdBuilder: CorrespondentQuery.fromId,
          queryParameterNotAssignedBuilder: CorrespondentQuery.notAssigned,
          prefixIcon: const Icon(Icons.person_outline),
        );
      },
    );
  }

  Widget _buildStoragePathFormField() {
    return BlocBuilder<LabelCubit<StoragePath>, LabelState<StoragePath>>(
      builder: (context, state) {
        return LabelFormField<StoragePath, StoragePathQuery>(
          formBuilderState: _formKey.currentState,
          name: fkStoragePath,
          state: state.labels,
          label: S.of(context).documentStoragePathPropertyLabel,
          initialValue: widget.initialFilter.storagePath,
          queryParameterIdBuilder: StoragePathQuery.fromId,
          queryParameterNotAssignedBuilder: StoragePathQuery.notAssigned,
          prefixIcon: const Icon(Icons.folder_outlined),
        );
      },
    );
  }

  Widget _buildQueryFormField() {
    final queryType =
        _formKey.currentState?.getRawValue(QueryTypeFormField.fkQueryType) ??
            QueryType.titleAndContent;
    late String label;
    switch (queryType) {
      case QueryType.title:
        label = S.of(context).documentFilterQueryOptionsTitleLabel;
        break;
      case QueryType.titleAndContent:
        label = S.of(context).documentFilterQueryOptionsTitleAndContentLabel;
        break;
      case QueryType.extended:
        label = S.of(context).documentFilterQueryOptionsExtendedLabel;
        break;
    }

    return FormBuilderTextField(
      name: fkQuery,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_outlined),
        labelText: label,
        suffixIcon: QueryTypeFormField(
          initialValue: widget.initialFilter.queryType,
          afterSelected: (queryType) => setState(() {}),
        ),
      ),
      initialValue: widget.initialFilter.queryText,
    );
  }

  Widget _buildDateRangePickerHelper(String formFieldKey) {
    const spacer = SizedBox(width: 8.0);
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          spacer,
          ActionChip(
            label: Text(
              S.of(context).documentFilterDateRangeLastSevenDaysLabel,
            ),
            onPressed: () {
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateUtils.addDaysToDate(DateTime.now(), -7),
                  end: DateTime.now(),
                ),
              );
            },
          ),
          spacer,
          ActionChip(
            label: Text(
              S.of(context).documentFilterDateRangeLastMonthLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth =
                  DateUtils.addMonthsToMonthDate(now, -1);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(firstDayOfLastMonth.year,
                      firstDayOfLastMonth.month, now.day),
                  end: DateTime.now(),
                ),
              );
            },
          ),
          spacer,
          ActionChip(
            label: Text(
              S.of(context).documentFilterDateRangeLastThreeMonthsLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth =
                  DateUtils.addMonthsToMonthDate(now, -3);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(
                    firstDayOfLastMonth.year,
                    firstDayOfLastMonth.month,
                    now.day,
                  ),
                  end: DateTime.now(),
                ),
              );
            },
          ),
          spacer,
          ActionChip(
            label: Text(
              S.of(context).documentFilterDateRangeLastYearLabel,
            ),
            onPressed: () {
              final now = DateTime.now();
              final firstDayOfLastMonth =
                  DateUtils.addMonthsToMonthDate(now, -12);
              _formKey.currentState?.fields[formFieldKey]?.didChange(
                DateTimeRange(
                  start: DateTime(
                    firstDayOfLastMonth.year,
                    firstDayOfLastMonth.month,
                    now.day,
                  ),
                  end: DateTime.now(),
                ),
              );
            },
          ),
          spacer,
        ],
      ),
    );
  }

  Widget _buildCreatedDateRangePickerFormField() {
    return Column(
      children: [
        FormBuilderDateRangePicker(
          initialValue: _dateTimeRangeOfNullable(
            widget.initialFilter.createdDateAfter,
            widget.initialFilter.createdDateBefore,
          ),
          // Workaround for theme data not being correctly passed to daterangepicker, see
          // https://github.com/flutter/flutter/issues/87580
          pickerBuilder: (context, Widget? child) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                    iconTheme:
                        IconThemeData(color: Theme.of(context).primaryColor),
                  ),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    onPrimary: Theme.of(context).primaryColor,
                    primary: Theme.of(context).colorScheme.primary,
                  ),
            ),
            child: child!,
          ),
          format: DateFormat.yMMMd(Localizations.localeOf(context).toString()),
          fieldStartLabelText:
              S.of(context).documentFilterDateRangeFieldStartLabel,
          fieldEndLabelText: S.of(context).documentFilterDateRangeFieldEndLabel,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now(),
          name: fkCreatedAt,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            labelText: S.of(context).documentCreatedPropertyLabel,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _formKey.currentState?.fields[fkCreatedAt]?.didChange(null);
              },
            ),
          ),
        ).paddedSymmetrically(horizontal: 8, vertical: 4.0),
        _buildDateRangePickerHelper(fkCreatedAt),
      ],
    );
  }

  Widget _buildAddedDateRangePickerFormField() {
    return Column(
      children: [
        FormBuilderDateRangePicker(
          initialValue: _dateTimeRangeOfNullable(
            widget.initialFilter.addedDateAfter,
            widget.initialFilter.addedDateBefore,
          ),
          // Workaround for theme data not being correctly passed to daterangepicker, see
          // https://github.com/flutter/flutter/issues/87580
          pickerBuilder: (context, Widget? child) => Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBarTheme: Theme.of(context).appBarTheme.copyWith(
                    iconTheme:
                        IconThemeData(color: Theme.of(context).primaryColor),
                  ),
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    onPrimary: Theme.of(context).primaryColor,
                    primary: Theme.of(context).colorScheme.primary,
                  ),
            ),
            child: child!,
          ),
          format: DateFormat.yMMMd(),
          fieldStartLabelText:
              S.of(context).documentFilterDateRangeFieldStartLabel,
          fieldEndLabelText: S.of(context).documentFilterDateRangeFieldEndLabel,
          firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
          lastDate: DateTime.now(),
          name: fkAddedAt,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            labelText: S.of(context).documentAddedPropertyLabel,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _formKey.currentState?.fields[fkAddedAt]?.didChange(null);
              },
            ),
          ),
        ).paddedSymmetrically(horizontal: 8),
        const SizedBox(height: 4.0),
        _buildDateRangePickerHelper(fkAddedAt),
      ],
    );
  }

  void _onApplyFilter() async {
    _formKey.currentState?.save();
    if (_formKey.currentState?.validate() ?? false) {
      final v = _formKey.currentState!.value;
      DocumentFilter newFilter = _assembleFilter();
      try {
        FocusScope.of(context).unfocus();
        Navigator.pop(context, newFilter);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      }
    }
  }

  DocumentFilter _assembleFilter() {
    final v = _formKey.currentState!.value;
    return DocumentFilter(
      createdDateBefore: (v[fkCreatedAt] as DateTimeRange?)?.end,
      createdDateAfter: (v[fkCreatedAt] as DateTimeRange?)?.start,
      correspondent: v[fkCorrespondent] as CorrespondentQuery? ??
          DocumentFilter.initial.correspondent,
      documentType: v[fkDocumentType] as DocumentTypeQuery? ??
          DocumentFilter.initial.documentType,
      storagePath: v[fkStoragePath] as StoragePathQuery? ??
          DocumentFilter.initial.storagePath,
      tags:
          v[DocumentModel.tagsKey] as TagsQuery? ?? DocumentFilter.initial.tags,
      queryText: v[fkQuery] as String?,
      addedDateBefore: (v[fkAddedAt] as DateTimeRange?)?.end,
      addedDateAfter: (v[fkAddedAt] as DateTimeRange?)?.start,
      queryType: v[QueryTypeFormField.fkQueryType] as QueryType,
      asnQuery: widget.initialFilter.asnQuery,
      page: 1,
      pageSize: widget.initialFilter.pageSize,
      sortField: widget.initialFilter.sortField,
      sortOrder: widget.initialFilter.sortOrder,
    );
  }
}

DateTimeRange? _dateTimeRangeOfNullable(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return null;
  }
  if (start != null && end != null) {
    return DateTimeRange(start: start, end: end);
  }
  assert(start != null || end != null);
  final singleDate = (start ?? end)!;
  return DateTimeRange(start: singleDate, end: singleDate);
}
