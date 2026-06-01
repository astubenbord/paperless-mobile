import 'package:flutter/material.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/store/bloc/current_user_app_state_builder.dart';
import 'package:paperless_mobile/core/translation/sort_field_localization_mapper.dart';
import 'package:paperless_mobile/features/documents/view/widgets/search/sort_field_selection_bottom_sheet.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';

class SortDocumentsButton extends StatelessWidget {
  final bool enabled;
  const SortDocumentsButton({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return CurrentUserAppDataBuilder(
      builder: (context, userData) {
        final filter = userData.appState.currentDocumentFilter;
        if (filter.sortField == null) {
          return const SizedBox.shrink();
        }
        final icon = Icon(
          filter.sortOrder == SortOrder.ascending
              ? Icons.arrow_upward
              : Icons.arrow_downward,
        );
        final label = Text(translateSortField(context, filter.sortField));
        final localStore = context.localStore;
        return ConnectivityAwareActionWrapper(
          offlineBuilder: (context, child) {
            return TextButton.icon(icon: icon, label: label, onPressed: null);
          },
          child: TextButton.icon(
            icon: icon,
            label: label,
            onPressed: enabled
                ? () {
                    showModalBottomSheet(
                      elevation: 2,
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => SortFieldSelectionBottomSheet(
                        initialSortField: filter.sortField,
                        initialSortOrder: filter.sortOrder,
                        onSubmit: (field, order) async {
                          localStore.updateCurrentDocumentFilter(
                            (filter) => filter.copyWith(
                              sortField: field,
                              sortOrder: order,
                            ),
                          );
                        },
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }
}
