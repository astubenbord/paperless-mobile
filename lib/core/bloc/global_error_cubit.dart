import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/core/model/error_message.dart';

///
/// Class for handling generic errors which usually only require to inform the user via a Snackbar
/// or similar that an error has occurred.
///
@singleton
class GlobalErrorCubit extends Cubit<GlobalErrorState> {
  static const _waitBeforeNextErrorDuration = Duration(seconds: 5);

  GlobalErrorCubit() : super(GlobalErrorState.initial);

  ///
  /// Adds a new error to this bloc. If the new error is equal to the current error, the new error
  /// will not be published unless the previous error occured over 5 seconds ago.
  ///
  void add(ErrorMessage error) {
    final now = DateTime.now();
    if (error != state.error || (error == state.error && _canEmitNewError())) {
      emit(GlobalErrorState(error: error, errorTimestamp: now));
    }
  }

  bool _canEmitNewError() {
    if (state.errorTimestamp != null) {
      return DateTime.now().difference(state.errorTimestamp!).inSeconds >= 5;
    }
    return true;
  }

  void reset() {
    emit(GlobalErrorState.initial);
  }
}

class GlobalErrorState {
  static const GlobalErrorState initial = GlobalErrorState();
  final ErrorMessage? error;
  final DateTime? errorTimestamp;

  const GlobalErrorState({this.error, this.errorTimestamp});

  bool get hasError => error != null;
}
