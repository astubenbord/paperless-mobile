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
            context.read<LabelRepository<StoragePath>>(),
          ),
        ),
        BlocProvider<LabelCubit<Correspondent>>(
          create: (context) => LabelCubit<Correspondent>(
            context.read<LabelRepository<Correspondent>>(),
          ),
        ),
        BlocProvider<LabelCubit<DocumentType>>(
          create: (context) => LabelCubit<DocumentType>(
            context.read<LabelRepository<DocumentType>>(),
          ),
        ),
        BlocProvider<LabelCubit<Tag>>(
          create: (context) => LabelCubit<Tag>(
            context.read<LabelRepository<Tag>>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
