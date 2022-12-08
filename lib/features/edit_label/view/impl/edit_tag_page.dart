import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/view/edit_label_page.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class EditTagPage extends StatelessWidget {
  final Tag tag;

  const EditTagPage({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelCubit<Tag>(
        RepositoryProvider.of<LabelRepository<Tag>>(context),
      ),
      child: EditLabelPage<Tag>(
        label: tag,
        fromJsonT: Tag.fromJson,
        additionalFields: [
          FormBuilderColorPickerField(
            initialValue: tag.color,
            name: Tag.colorKey,
            decoration: InputDecoration(
              label: Text(S.of(context).tagColorPropertyLabel),
            ),
            colorPickerType: ColorPickerType.blockPicker,
          ),
          FormBuilderCheckbox(
            initialValue: tag.isInboxTag,
            name: Tag.isInboxTagKey,
            title: Text(S.of(context).tagInboxTagPropertyLabel),
          ),
        ],
      ),
    );
  }
}
