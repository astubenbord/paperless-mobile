import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/edit_label_page.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';

class EditCorrespondentPage extends StatelessWidget {
  final Correspondent correspondent;
  const EditCorrespondentPage({super.key, required this.correspondent});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<Correspondent>(
        context.read<LabelRepository<Correspondent>>(),
      ),
      child: EditLabelPage<Correspondent>(
        label: correspondent,
        fromJsonT: Correspondent.fromJson,
      ),
    );
  }
}
