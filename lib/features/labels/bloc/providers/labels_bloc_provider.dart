import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/labels/bloc/label_cubit.dart';

class LabelsBlocProvider extends StatelessWidget {
  final Widget child;
  const LabelsBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LabelCubit<StoragePath>>(
          create: (context) => LabelCubit<StoragePath>(
            RepositoryProvider.of<LabelRepository<StoragePath>>(context),
          ),
        ),
        BlocProvider<LabelCubit<Correspondent>>(
          create: (context) => LabelCubit<Correspondent>(
            RepositoryProvider.of<LabelRepository<Correspondent>>(context),
          ),
        ),
        BlocProvider<LabelCubit<DocumentType>>(
          create: (context) => LabelCubit<DocumentType>(
            RepositoryProvider.of<LabelRepository<DocumentType>>(context),
          ),
        ),
        BlocProvider<LabelCubit<Tag>>(
          create: (context) => LabelCubit<Tag>(
            RepositoryProvider.of<LabelRepository<Tag>>(context),
          ),
        ),
      ],
      child: child,
    );
  }
}
