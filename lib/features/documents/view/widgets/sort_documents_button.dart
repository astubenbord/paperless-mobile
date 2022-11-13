import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_state.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/sort_order.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:paperless_mobile/util.dart';

class SortDocumentsButton extends StatefulWidget {
  const SortDocumentsButton({
    Key? key,
  }) : super(key: key);

  @override
  State<SortDocumentsButton> createState() => _SortDocumentsButtonState();
}

class _SortDocumentsButtonState extends State<SortDocumentsButton> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (context, state) {
        Widget child;
        if (_isLoading) {
          child = const FittedBox(
            fit: BoxFit.scaleDown,
            child: RefreshProgressIndicator(
              strokeWidth: 4.0,
              backgroundColor: Colors.transparent,
            ),
          );
        } else {
          final bool isAscending =
              state.filter.sortOrder == SortOrder.ascending;
          child = IconButton(
            icon: FaIcon(
              isAscending
                  ? FontAwesomeIcons.arrowDownAZ
                  : FontAwesomeIcons.arrowUpZA,
            ),
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await BlocProvider.of<DocumentsCubit>(context)
                    .updateCurrentFilter(
                  (filter) => filter.copyWith(
                    sortOrder: state.filter.sortOrder.toggle(),
                  ),
                );
              } on ErrorMessage catch (error) {
                showError(context, error);
              } finally {
                setState(() => _isLoading = false);
              }
            },
          );
        }
        return SizedBox(
          height: Theme.of(context).iconTheme.size,
          width: Theme.of(context).iconTheme.size,
          child: child,
        );
      },
    );
  }
}
