import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class AddTagPage extends StatelessWidget {
  final String? initialValue;
  const AddTagPage({Key? key, this.initialValue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<Tag>(
        RepositoryProvider.of<LabelRepository<Tag>>(context),
      ),
      child: AddLabelPage<Tag>(
        pageTitle: Text(S.of(context).addTagPageTitle),
        fromJsonT: Tag.fromJson,
        initialName: initialValue,
        additionalFields: [
          FormBuilderColorPickerField(
            name: Tag.colorKey,
            valueTransformer: (color) => "#${color?.value.toRadixString(16)}",
            decoration: InputDecoration(
              label: Text(S.of(context).tagColorPropertyLabel),
            ),
            colorPickerType: ColorPickerType.materialPicker,
            initialValue: null,
          ),
          FormBuilderCheckbox(
            name: Tag.isInboxTagKey,
            title: Text(S.of(context).tagInboxTagPropertyLabel),
          ),
        ],
      ),
    );
  }
}
