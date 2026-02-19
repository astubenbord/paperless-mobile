import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/ai_chat/cubit/ai_chat_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<AiChatCubit>().sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.aiChat),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AiChatCubit, AiChatState>(
              listener: (context, state) => _scrollToBottom(),
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.of(context)!.aiChat,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask questions about your documents',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length +
                      (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return _buildMessageBubble(
                        context, state.messages[index]);
                  },
                );
              },
            ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
            ),
            if (message.references.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: message.references.map((ref) {
                  return ActionChip(
                    avatar: const Icon(Icons.description, size: 14),
                    label: Text(
                      ref.title,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    onPressed: () {
                      DocumentDetailsRoute(
                        id: ref.id,
                        title: ref.title,
                      ).push(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: S.of(context)!.typeAMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<AiChatCubit, AiChatState>(
            builder: (context, state) {
              return IconButton.filled(
                onPressed: state.isLoading ? null : _sendMessage,
                icon: const Icon(Icons.send),
              );
            },
          ),
        ],
      ),
    );
  }
}
