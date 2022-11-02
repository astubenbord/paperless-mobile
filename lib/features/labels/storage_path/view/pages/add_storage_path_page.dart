import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/model/storage_path.model.dart';
import 'package:paperless_mobile/features/labels/storage_path/view/widgets/storage_path_autofill_form_builder_field.dart';
import 'package:paperless_mobile/features/labels/view/pages/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class AddStoragePathPage extends StatelessWidget {
  final String? initalValue;
  const AddStoragePathPage({Key? key, this.initalValue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddLabelPage<StoragePath>(
      addLabelStr: S.of(context).addStoragePathPageTitle,
      fromJson: StoragePath.fromJson,
      cubit: BlocProvider.of<StoragePathCubit>(context),
      initialName: initalValue,
      additionalFields: const [
        StoragePathAutofillFormBuilderField(name: StoragePath.pathKey),
        SizedBox(height: 120.0),
      ],
    );
  }
}
