import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';

class LabelRepositoriesProvider extends StatelessWidget {
  final Widget child;
  const LabelRepositoriesProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => context.read<LabelRepository<Correspondent>>(),
        ),
        RepositoryProvider(
          create: (context) => context.read<LabelRepository<DocumentType>>(),
        ),
        RepositoryProvider(
          create: (context) => context.read<LabelRepository<StoragePath>>(),
        ),
        RepositoryProvider(
          create: (context) => context.read<LabelRepository<Tag>>(),
        ),
      ],
      child: child,
    );
  }
}
