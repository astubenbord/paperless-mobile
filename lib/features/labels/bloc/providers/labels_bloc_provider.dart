import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';
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
            context.read<
                LabelRepository<StoragePath, StoragePathRepositoryState>>(),
          ),
        ),
        BlocProvider<LabelCubit<Correspondent>>(
          create: (context) => LabelCubit<Correspondent>(
            context.read<
                LabelRepository<Correspondent, CorrespondentRepositoryState>>(),
          ),
        ),
        BlocProvider<LabelCubit<DocumentType>>(
          create: (context) => LabelCubit<DocumentType>(
            context.read<
                LabelRepository<DocumentType, DocumentTypeRepositoryState>>(),
          ),
        ),
        BlocProvider<LabelCubit<Tag>>(
          create: (context) => LabelCubit<Tag>(
            context.read<LabelRepository<Tag, TagRepositoryState>>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
