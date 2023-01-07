import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/impl/document_type_repository_impl.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/state/impl/correspondent_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/document_type_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/storage_path_repository_state.dart';
import 'package:paperless_mobile/core/repository/state/impl/tag_repository_state.dart';

class LabelRepositoriesProvider extends StatelessWidget {
  final Widget child;
  const LabelRepositoriesProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => context.read<
              LabelRepository<Correspondent, CorrespondentRepositoryState>>(),
        ),
        RepositoryProvider(
          create: (context) => context.read<
              LabelRepository<DocumentType, DocumentTypeRepositoryState>>(),
        ),
        RepositoryProvider(
          create: (context) => context
              .read<LabelRepository<StoragePath, StoragePathRepositoryState>>(),
        ),
        RepositoryProvider(
          create: (context) =>
              context.read<LabelRepository<Tag, TagRepositoryState>>(),
        ),
      ],
      child: child,
    );
  }
}
