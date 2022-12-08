import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';

class StoragePathBlocProvider extends StatelessWidget {
  final Widget child;
  const StoragePathBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LabelCubit<StoragePath>(
        RepositoryProvider.of<LabelRepository<StoragePath>>(context),
      ),
      child: child,
    );
  }
}
