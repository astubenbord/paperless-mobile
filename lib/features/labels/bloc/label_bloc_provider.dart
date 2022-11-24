import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/di_initializer.dart';
import 'package:paperless_mobile/features/documents/bloc/saved_view_cubit.dart';
import 'package:paperless_mobile/features/labels/correspondent/bloc/correspondents_cubit.dart';
import 'package:paperless_mobile/features/labels/document_type/bloc/document_type_cubit.dart';
import 'package:paperless_mobile/features/labels/storage_path/bloc/storage_path_cubit.dart';
import 'package:paperless_mobile/features/labels/tags/bloc/tags_cubit.dart';

class LabelBlocProvider extends StatelessWidget {
  final Widget child;
  const LabelBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<DocumentTypeCubit>()),
        BlocProvider.value(value: getIt<CorrespondentCubit>()),
        BlocProvider.value(value: getIt<TagCubit>()),
        BlocProvider.value(value: getIt<StoragePathCubit>()),
        BlocProvider.value(value: getIt<SavedViewCubit>()),
      ],
      child: child,
    );
  }
}
