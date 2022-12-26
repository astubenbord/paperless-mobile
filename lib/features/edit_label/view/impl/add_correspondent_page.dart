import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/edit_label/cubit/edit_label_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class AddCorrespondentPage extends StatelessWidget {
  final String? initialName;
  const AddCorrespondentPage({Key? key, this.initialName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditLabelCubit<Correspondent>(
        context.read<LabelRepository<Correspondent>>(),
      ),
      child: AddLabelPage<Correspondent>(
        pageTitle: Text(S.of(context).addCorrespondentPageTitle),
        fromJsonT: Correspondent.fromJson,
        initialName: initialName,
      ),
    );
  }
}
