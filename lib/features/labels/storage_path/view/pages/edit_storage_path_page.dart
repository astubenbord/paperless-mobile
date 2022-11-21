import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/logic/error_code_localization_mapper.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/storage_path_query.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/widgets/storage_path_autofill_form_builder_field.dart';
import 'package:paperless_mobile/features/labels/view/pages/edit_label_page.dart';
import 'package:paperless_mobile/util.dart';

class EditStoragePathPage extends StatelessWidget {
  final StoragePath storagePath;
  const EditStoragePathPage({super.key, required this.storagePath});

  @override
  Widget build(BuildContext context) {
    return EditLabelPage<StoragePath>(
      label: storagePath,
      onSubmit: BlocProvider.of<StoragePathCubit>(context).replace,
      onDelete: (correspondent) => _onDelete(correspondent, context),
      fromJson: StoragePath.fromJson,
      additionalFields: [
        StoragePathAutofillFormBuilderField(
          name: StoragePath.pathKey,
          initialValue: storagePath.path,
        ),
        const SizedBox(height: 120.0),
      ],
    );
  }

  Future<void> _onDelete(StoragePath path, BuildContext context) async {
    try {
      await BlocProvider.of<StoragePathCubit>(context).remove(path);
      final cubit = BlocProvider.of<DocumentsCubit>(context);
      if (cubit.state.filter.storagePath.id == path.id) {
        cubit.updateCurrentFilter(
          (filter) => filter.copyWith(
            storagePath: const StoragePathQuery.unset(),
          ),
        );
      }
      Navigator.pop(context);
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
