import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/translation/sort_field_localization_mapper.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class SortFieldSelectionBottomSheet extends StatefulWidget {
  final SortOrder initialSortOrder;
  final SortField? initialSortField;

  final Future Function(SortField? field, SortOrder order) onSubmit;

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
  late SortField? _currentSortField;
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context)!.orderBy,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.start,
                ),
                TextButton(
                  child: Text(S.of(context)!.apply),
                  onPressed: () async {
                    await widget.onSubmit(_currentSortField, _currentSortOrder);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ).paddedOnly(left: 16, right: 16, top: 8),
            Column(
              children: [
                _buildSortOption(SortField.archiveSerialNumber),
                if (context.uiSettings.canViewCorrespondents)
                  QueryBuilder(
                    query: context.correspondentRepository.getAllQuery(),
                    builder: (context, state) {
                      return _buildSortOption(
                        SortField.correspondentName,
                        loading: state.isLoading,
                        enabled:
                            state.data?.any(
                              (element) => (element.documentCount ?? 0) > 0,
                            ) ??
                            false,
                      );
                    },
                  ),
                _buildSortOption(SortField.title),
                if (context.uiSettings.canViewDocumentTypes)
                  QueryBuilder(
                    query: context.documentTypeRepository.getAllQuery(),
                    builder: (context, state) {
                      return _buildSortOption(
                        SortField.documentType,
                        loading: state.isLoading,
                        enabled:
                            state.data?.any(
                              (element) => (element.documentCount ?? 0) > 0,
                            ) ??
                            false,
                      );
                    },
                  ),
                _buildSortOption(SortField.created),
                _buildSortOption(SortField.added),
                _buildSortOption(SortField.modified),
                const SizedBox(height: 16),
                Center(
                  child: SegmentedButton(
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        icon: const FaIcon(FontAwesomeIcons.arrowDownZA),
                        value: SortOrder.descending,
                        label: Text(S.of(context)!.descending),
                      ),
                      ButtonSegment(
                        icon: const FaIcon(FontAwesomeIcons.arrowDownAZ),
                        value: SortOrder.ascending,
                        label: Text(S.of(context)!.ascending),
                      ),
                    ],
                    emptySelectionAllowed: false,
                    selected: {_currentSortOrder},
                    onSelectionChanged: (selection) {
                      setState(() => _currentSortOrder = selection.first);
                    },
                  ),
                ).paddedOnly(bottom: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    SortField field, {
    bool enabled = true,
    bool loading = false,
  }) {
    return ListTile(
      leading: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      enabled: enabled && !loading,
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text(translateSortField(context, field)),
      trailing: _currentSortField == field ? const Icon(Icons.done) : null,
      onTap: () {
        setState(() => _currentSortField = field);
      },
    );
  }
}
