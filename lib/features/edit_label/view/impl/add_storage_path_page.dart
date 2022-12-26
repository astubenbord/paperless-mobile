import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/add_label_page.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/widgets/storage_path_autofill_form_builder_field.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class AddStoragePathPage extends StatelessWidget {
  final String? initalValue;
  const AddStoragePathPage({Key? key, this.initalValue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<StoragePath>(
        context.read<LabelRepository<StoragePath>>(),
      ),
      child: AddLabelPage<StoragePath>(
        pageTitle: Text(S.of(context).addStoragePathPageTitle),
        fromJsonT: StoragePath.fromJson,
        initialName: initalValue,
        additionalFields: const [
          StoragePathAutofillFormBuilderField(name: StoragePath.pathKey),
          SizedBox(height: 120.0),
        ],
      ),
    );
  }
}
