import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_field.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_order.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';

class SortFieldSelectionBottomSheet extends StatefulWidget {
  const SortFieldSelectionBottomSheet({super.key});

  @override
  State<SortFieldSelectionBottomSheet> createState() =>
      _SortFieldSelectionBottomSheetState();
}

class _SortFieldSelectionBottomSheetState
    extends State<SortFieldSelectionBottomSheet> {
  static const _sortFields = [
    SortField.created,
    SortField.added,
    SortField.modified,
    SortField.title,
    SortField.correspondentName,
    SortField.documentType,
    SortField.archiveSerialNumber
  ];

  SortField? _selectedFieldLoading;
  SortOrder? _selectedOrderLoading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BlocBuilder<DocumentsCubit, DocumentsState>(
        bloc: getIt<DocumentsCubit>(),
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).documentsPageOrderByLabel,
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.start,
              ).padded(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
              Column(
                children: _sortFields
                    .map(
                      (e) => _buildSortOption(
                        e,
                        state.filter.sortOrder,
                        state.filter.sortField == e,
                        _selectedFieldLoading == e,
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortOption(
    SortField field,
    SortOrder order,
    bool isCurrentlySelected,
    bool isNextSelected,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      title: Text(
        _localizedSortField(field),
        style: Theme.of(context).textTheme.bodyText2,
      ),
      trailing: isNextSelected
          ? (_buildOrderIcon(_selectedOrderLoading!))
          : (_selectedOrderLoading == null && isCurrentlySelected
              ? _buildOrderIcon(order)
              : null),
      onTap: () async {
        setState(() {
          _selectedFieldLoading = field;
          _selectedOrderLoading =
              isCurrentlySelected ? order.toggle() : SortOrder.descending;
        });
        BlocProvider.of<DocumentsCubit>(context)
            .updateCurrentFilter((filter) => filter.copyWith(
                  sortOrder: isCurrentlySelected
                      ? order.toggle()
                      : SortOrder.descending,
                  sortField: field,
                ))
            .whenComplete(() {
          if (mounted) {
            setState(() {
              _selectedFieldLoading = null;
              _selectedOrderLoading = null;
            });
          }
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
