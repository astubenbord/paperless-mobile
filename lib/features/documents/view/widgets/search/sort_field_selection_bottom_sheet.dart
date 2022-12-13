import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/features/labels/bloc/label_state.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class SortFieldSelectionBottomSheet extends StatefulWidget {
  final SortOrder initialSortOrder;
  final SortField initialSortField;

  final Future Function(SortField field, SortOrder order) onSubmit;

  const SortFieldSelectionBottomSheet({
    super.key,
    required this.initialSortOrder,
    required this.initialSortField,
    required this.onSubmit,
  });

  @override
  State<SortFieldSelectionBottomSheet> createState() =>
      _SortFieldSelectionBottomSheetState();
}

class _SortFieldSelectionBottomSheetState
    extends State<SortFieldSelectionBottomSheet> {
  late SortField _currentSortField;
  late SortOrder _currentSortOrder;

  @override
  void initState() {
    super.initState();
    _currentSortField = widget.initialSortField;
    _currentSortOrder = widget.initialSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).documentsPageOrderByLabel,
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.start,
              ),
              TextButton(
                child: Text(S.of(context).documentFilterApplyFilterLabel),
                onPressed: () {
                  widget.onSubmit(
                    _currentSortField,
                    _currentSortOrder,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ).paddedSymmetrically(horizontal: 16, vertical: 8.0),
          Column(
            children: [
              _buildSortOption(SortField.archiveSerialNumber),
              BlocBuilder<LabelCubit<Correspondent>, LabelState<Correspondent>>(
                builder: (context, state) {
                  return _buildSortOption(
                    SortField.correspondentName,
                    enabled: state.labels.values.fold<bool>(
                        false,
                        (previousValue, element) =>
                            previousValue || (element.documentCount ?? 0) > 0),
                  );
                },
              ),
              _buildSortOption(SortField.title),
              BlocBuilder<LabelCubit<DocumentType>, LabelState<DocumentType>>(
                builder: (context, state) {
                  return _buildSortOption(
                    SortField.documentType,
                    enabled: state.labels.values.fold<bool>(
                        false,
                        (previousValue, element) =>
                            previousValue || (element.documentCount ?? 0) > 0),
                  );
                },
              ),
              _buildSortOption(SortField.created),
              _buildSortOption(SortField.added),
              _buildSortOption(SortField.modified),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(SortField field, {bool enabled = true}) {
    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Text(
        _localizedSortField(field),
      ),
      trailing: _currentSortField == field
          ? _buildOrderIcon(_currentSortOrder)
          : null,
      onTap: () {
        setState(() {
          _currentSortOrder = (_currentSortField == field
              ? _currentSortOrder.toggle()
              : SortOrder.descending);
          _currentSortField = field;
        });
      },
    );
  }

  Widget _buildOrderIcon(SortOrder order) {
    if (order == SortOrder.ascending) {
      return const Icon(Icons.arrow_upward);
    }
    return const Icon(Icons.arrow_downward);
  }

  String _localizedSortField(SortField sortField) {
    switch (sortField) {
      case SortField.archiveSerialNumber:
        return S.of(context).documentArchiveSerialNumberPropertyShortLabel;
      case SortField.correspondentName:
        return S.of(context).documentCorrespondentPropertyLabel;
      case SortField.title:
        return S.of(context).documentTitlePropertyLabel;
      case SortField.documentType:
        return S.of(context).documentDocumentTypePropertyLabel;
      case SortField.created:
        return S.of(context).documentCreatedPropertyLabel;
      case SortField.added:
        return S.of(context).documentAddedPropertyLabel;
      case SortField.modified:
        return S.of(context).documentModifiedPropertyLabel;
    }
  }
}
