import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';

class BlocChangesObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }
}
