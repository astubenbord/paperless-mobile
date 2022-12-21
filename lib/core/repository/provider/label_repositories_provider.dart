import 'package:flutter/src/widgets/framework.dart';
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
          create: (context) =>
              RepositoryProvider.of<LabelRepository<Correspondent>>(context),
        ),
        RepositoryProvider(
          create: (context) =>
              RepositoryProvider.of<LabelRepository<DocumentType>>(context),
        ),
        RepositoryProvider(
          create: (context) =>
              RepositoryProvider.of<LabelRepository<StoragePath>>(context),
        ),
        RepositoryProvider(
          create: (context) =>
              RepositoryProvider.of<LabelRepository<Tag>>(context),
        ),
      ],
      child: child,
    );
  }
}
