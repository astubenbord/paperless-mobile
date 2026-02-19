part of 'ai_chat_cubit.dart';

class DocumentReference {
  final int id;
  final String title;

  const DocumentReference({required this.id, required this.title});
}

class ChatMessage {
  final String role;
  final String content;
  final List<DocumentReference> references;

  const ChatMessage({
    required this.role,
    required this.content,
    this.references = const [],
  });
}

class AiChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoading;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading];
}
