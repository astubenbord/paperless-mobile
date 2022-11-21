import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/correspondent_query.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/model/correspondent.model.dart';
import 'package:paperless_mobile/features/labels/view/pages/edit_label_page.dart';
import 'package:paperless_mobile/util.dart';

class EditCorrespondentPage extends StatelessWidget {
  final Correspondent correspondent;
  const EditCorrespondentPage({super.key, required this.correspondent});

  @override
  Widget build(BuildContext context) {
    return EditLabelPage<Correspondent>(
      label: correspondent,
      onSubmit: BlocProvider.of<CorrespondentCubit>(context).replace,
      onDelete: (correspondent) => _onDelete(context, correspondent),
      fromJson: Correspondent.fromJson,
    );
  }

  Future<void> _onDelete(
    BuildContext context,
    Correspondent correspondent,
  ) async {
    try {
      await BlocProvider.of<CorrespondentCubit>(context).remove(correspondent);
      final cubit = BlocProvider.of<DocumentsCubit>(context);
      if (cubit.state.filter.correspondent.id == correspondent.id) {
        await cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
            correspondent: const CorrespondentQuery.unset(),
          ),
        );
      }
      Navigator.pop(context);
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
