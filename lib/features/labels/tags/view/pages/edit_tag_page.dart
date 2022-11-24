import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/core/bloc/paperless_statistics_cubit.dart';
import 'package:paperless_mobile/core/model/error_message.dart';
import 'package:paperless_mobile/features/documents/bloc/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/query_parameters/tags_query.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/model/tag.model.dart';
import 'package:paperless_mobile/features/labels/view/pages/edit_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:paperless_mobile/util.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';

class EditTagPage extends StatelessWidget {
  final Tag tag;

  const EditTagPage({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    return EditLabelPage<Tag>(
      label: tag,
      onSubmit: (tag) async {
        await BlocProvider.of<TagCubit>(context).replace(tag);
        //If inbox property was added/removed from tag, the number of documents in inbox may increase/decrease.
        BlocProvider.of<PaperlessStatisticsCubit>(context).updateStatistics();
      },
      onDelete: (tag) => _onDelete(tag, context),
      fromJson: Tag.fromJson,
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
    );
  }

  Future<void> _onDelete(Tag tag, BuildContext context) async {
    try {
      await BlocProvider.of<TagCubit>(context).remove(tag);
      final cubit = BlocProvider.of<DocumentsCubit>(context);
      final currentFilter = cubit.state.filter;
      late DocumentFilter updatedFilter = currentFilter;
      if (currentFilter.tags is IdsTagsQuery) {
        if ((currentFilter.tags as IdsTagsQuery).includedIds.contains(tag.id)) {
          updatedFilter = currentFilter.copyWith(
            tags: (currentFilter.tags as IdsTagsQuery).withIdsRemoved(
              [tag.id!],
            ),
          );
        }
      }
      cubit.updateFilter(filter: updatedFilter);
      Navigator.pop(context);
    } on ErrorMessage catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    }
  }
}
