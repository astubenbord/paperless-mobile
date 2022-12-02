import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/view/pages/add_label_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class AddCorrespondentPage extends StatelessWidget {
  final String? initalValue;
  const AddCorrespondentPage({Key? key, this.initalValue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AddLabelPage<Correspondent>(
      addLabelStr: S.of(context).addCorrespondentPageTitle,
      fromJson: Correspondent.fromJson,
      cubit: BlocProvider.of<CorrespondentCubit>(context),
      initialName: initalValue,
    );
  }
}
