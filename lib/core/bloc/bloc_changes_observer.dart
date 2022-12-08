import 'package:flutter_bloc/flutter_bloc.dart';

class BlocChangesObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }
}
