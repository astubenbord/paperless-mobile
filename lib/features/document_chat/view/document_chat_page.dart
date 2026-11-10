import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/features/document_chat/cubit/document_chat_cubit.dart';
import 'package:paperless_mobile/features/document_chat/model/document_chat_message.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/connectivity_aware_action_wrapper.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/routing/routes/documents_route.dart';

class DocumentChatPage extends StatefulWidget {
  final String? documentTitle;

  const DocumentChatPage({super.key, this.documentTitle});

  @override
  State<DocumentChatPage> createState() => _DocumentChatPageState();
}

class _DocumentChatPageState extends State<DocumentChatPage> {
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDocumentChat = context.read<DocumentChatCubit>().documentId != null;
    final title = isDocumentChat
        ? S.of(context)!.chatWithDocument
        : S.of(context)!.chatWithDocuments;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (widget.documentTitle?.isNotEmpty ?? false)
              Text(
                widget.documentTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ),
      body: BlocConsumer<DocumentChatCubit, DocumentChatState>(
        listenWhen: (previous, current) =>
            previous.messages.lastOrNull?.error == null &&
            current.messages.lastOrNull?.error != null,
        listener: (context, state) {
          showGenericError(context, state.messages.last.error);
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: HintCard(
                            hintText: S.of(context)!.chatAiDisclaimer,
                            hintIcon: Icons.auto_awesome_outlined,
                          ).padded(16),
                        ),
                      )
                    // Reversed to keep the streamed answer in view
                    : ListView.separated(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ChatMessageBubble(
                          message:
                              state.messages[state.messages.length - 1 - index],
                        ),
                      ),
              ),
              _buildQuestionInput(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionInput(BuildContext context, DocumentChatState state) {
    return SafeArea(
      top: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: state.isAnswering ? null : (_) => _ask(),
              decoration: InputDecoration(
                hintText: S.of(context)!.askAQuestion,
              ),
            ),
          ),
          ConnectivityAwareActionWrapper(
            child: ValueListenableBuilder(
              valueListenable: _questionController,
              builder: (context, value, _) {
                return IconButton.filled(
                  tooltip: S.of(context)!.send,
                  icon: const Icon(Icons.send),
                  onPressed: state.isAnswering || value.text.trim().isEmpty
                      ? null
                      : _ask,
                );
              },
            ),
          ),
        ],
      ).paddedLTRB(16, 8, 16, 8),
    );
  }

  void _ask() {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      return;
    }
    _questionController.clear();
    context.read<DocumentChatCubit>().ask(question);
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final DocumentChatMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == DocumentChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (message.content.isNotEmpty)
                SelectableText(
                  message.content,
                  style: TextStyle(
                    color: isUser
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              if (message.isStreaming && message.content.isEmpty)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (message.error != null)
                Text(
                  S.of(context)!.documentChatFailed,
                  style: TextStyle(color: colorScheme.error),
                ),
              if (message.references.isNotEmpty) ...[
                Text(
                  S.of(context)!.sources,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final reference in message.references)
                      ActionChip(
                        avatar: const Icon(Icons.description_outlined),
                        label: Text(
                          reference.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => DocumentDetailsRoute(
                          documentId: reference.id,
                          title: reference.title,
                        ).push(context),
                      ),
                  ],
                ),
              ],
            ],
          ).padded(12),
        ),
      ),
    );
  }
}
