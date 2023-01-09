part of 'notification_cubit.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object> get props => [];
}

class NotificationInitialState extends NotificationState {}

class NotificationOpenDocumentDetailsPageState extends NotificationState {
  final int documentId;

  const NotificationOpenDocumentDetailsPageState(this.documentId);
}
