import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/features/labels/view/pages/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';

class AddTagPage extends StatelessWidget {
  const AddTagPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddLabelPage<Tag>(
      addLabelStr: S.of(context).addTagPageTitle,
      fromJson: Tag.fromJson,
      cubit: BlocProvider.of<TagCubit>(context),
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
    );
  }
}
