import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/repository/document_repository.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/core/widgets/hint_state_builder.dart';
import 'package:paperless_mobile/core/widgets/icon_loading_widget.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DocumentNotesWidget extends StatefulWidget {
  final int documentId;
  const DocumentNotesWidget({super.key, required this.documentId});

  @override
  State<DocumentNotesWidget> createState() => _DocumentNotesWidgetState();
}

class _DocumentNotesWidgetState extends State<DocumentNotesWidget> {
  final _noteContentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    const hintKey = "hideMarkdownSyntaxHint";
    return QueryBuilder(
      query: context.read<DocumentRepository>().getAllNotesQuery(
        widget.documentId,
      ),
      builder: (context, state) {
        if (state.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.isError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text(
                state.error.toString(), //TODO: INTL better error message
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error.withAlpha(200),
                ),
              ),
            ),
          );
        }
        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverToBoxAdapter(
                child: HintStateBuilder(
                  listenKey: hintKey,
                  builder: (context, acknowledged, acknowledge) {
                    debugPrint("Acknowledged: $acknowledged");
                    return HintCard(
                      hintText: S.of(context)!.notesMarkdownSyntaxSupportHint,
                      show: !acknowledged,
                      onAcknowledgeHint: acknowledge,
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _noteContentController,
                      maxLines: null,
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return S.of(context)!.thisFieldIsRequired;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: S.of(context)!.newNote,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _noteContentController.clear();
                          },
                        ),
                      ),
                    ).paddedOnly(bottom: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MutationBuilder(
                        mutation: context.documentRepository.addNoteMutation(
                          widget.documentId,
                        ),
                        builder: (context, state, addNote) {
                          return FilledButton.tonalIcon(
                            icon: switch (state) {
                              MutationLoading() => SizedBox.square(
                                dimension: 20,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                              _ => const Icon(Icons.note_add_outlined),
                            },
                            label: Text(S.of(context)!.addNote),
                            onPressed: () async {
                              _formKey.currentState?.save();
                              FocusScope.of(context).unfocus();

                              if (_formKey.currentState?.validate() ?? false) {
                                final value = _noteContentController.text
                                    .trim();
                                try {
                                  await addNote(value);
                                  _noteContentController.clear();
                                } catch (error) {
                                  if (context.mounted) {
                                    showGenericError(context, error);
                                  }
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverList.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final note = state.data![index];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Html(
                        data: markdownToHtml(note.note ?? ''),
                        onLinkTap: (url, attributes, element) async {
                          if (url?.isEmpty ?? true) {
                            return;
                          }
                          if (await canLaunchUrlString(url!)) {
                            launchUrlString(url);
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (note.created != null)
                            Text(
                              context.displayDateFormat
                                  .addPattern('\u2014')
                                  .add_jm()
                                  .format(note.created!),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(128),
                                  ),
                            ),
                          MutationBuilder(
                            key: ValueKey(
                              '${widget.documentId}-${note.id.toString()}',
                            ),
                            mutation: context.documentRepository
                                .deleteNoteMutation(widget.documentId, note.id),
                            builder: (context, mutationState, deleteNote) {
                              return IconButton(
                                tooltip: S.of(context)!.delete,
                                icon: mutationState.isLoading
                                    ? IconLoadingWidget()
                                    : const Icon(Icons.delete),
                                onPressed: () {
                                  deleteNote(null);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ).padded(16),
                );
              },
              itemCount: state.data!.length,
            ),
          ],
        );
      },
    );
  }
}
