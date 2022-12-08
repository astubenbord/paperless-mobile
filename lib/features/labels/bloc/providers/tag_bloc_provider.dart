import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';

class TagBlocProvider extends StatelessWidget {
  final Widget child;
  const TagBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelCubit<Tag>(
        RepositoryProvider.of<LabelRepository<Tag>>(context),
      ),
      child: child,
    );
  }
}
