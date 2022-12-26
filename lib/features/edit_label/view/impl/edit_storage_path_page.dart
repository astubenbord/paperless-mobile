import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/edit_label_page.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/widgets/storage_path_autofill_form_builder_field.dart';

class EditStoragePathPage extends StatelessWidget {
  final StoragePath storagePath;
  const EditStoragePathPage({super.key, required this.storagePath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<StoragePath>(
        context.read<LabelRepository<StoragePath>>(),
      ),
      child: EditLabelPage<StoragePath>(
        label: storagePath,
        fromJsonT: StoragePath.fromJson,
        additionalFields: [
          StoragePathAutofillFormBuilderField(
            name: StoragePath.pathKey,
            initialValue: storagePath.path,
          ),
          const SizedBox(height: 120.0),
        ],
      ),
    );
  }
}
