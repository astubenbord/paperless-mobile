part of 'receive_share_cubit.dart';

sealed class ReceiveShareState {
  final List<File> files;

  const ReceiveShareState({this.files = const []});
}

class ReceiveShareStateInitial extends ReceiveShareState {
  const ReceiveShareStateInitial();
}

class ReceiveShareStateLoading extends ReceiveShareState {
  const ReceiveShareStateLoading();
}

class ReceiveShareStateLoaded extends ReceiveShareState {
  const ReceiveShareStateLoaded({super.files});

  ReceiveShareStateLoaded copyWith({List<File>? files}) {
    return ReceiveShareStateLoaded(files: files ?? this.files);
  }
}

class ReceiveShareStateError extends ReceiveShareState {
  final String message;
  const ReceiveShareStateError(this.message);
}
