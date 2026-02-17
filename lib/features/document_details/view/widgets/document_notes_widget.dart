import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/core/widgets/hint_state_builder.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/util/message_helpers.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;
import 'package:url_launcher/url_launcher_string.dart';

class DocumentNotesWidget extends StatefulWidget {
  final DocumentModel document;
  const DocumentNotesWidget({super.key, required this.document});

  @override
  State<DocumentNotesWidget> createState() => _DocumentNotesWidgetState();
}

class _DocumentNotesWidgetState extends State<DocumentNotesWidget> {
  final _noteContentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isNoteSubmitting = false;
  @override
  Widget build(BuildContext context) {
    const hintKey = "hideMarkdownSyntaxHint";
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 16),
          sliver: SliverToBoxAdapter(
            child: HintStateBuilder(
              listenKey: hintKey,
              builder: (context, box) {
                return HintCard(
                  hintText: S.of(context)!.notesMarkdownSyntaxSupportHint,
                  show: !box.get(hintKey, defaultValue: false)!,
                  onHintAcknowledged: () {
                    box.put(hintKey, true);
                  },
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
                  child: ElevatedButton.icon(
                    icon: _isNoteSubmitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : const Icon(Icons.note_add_outlined),
                    label: Text(S.of(context)!.addNote),
                    onPressed: () async {
                      _formKey.currentState?.save();
                      FocusScope.of(context).unfocus();

                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _isNoteSubmitting = true;
                        });
                        try {
                          await context
                              .read<DocumentDetailsCubit>()
                              .addNote(_noteContentController.text.trim());
                          _noteContentController.clear();
                        } catch (error) {
                          if (context.mounted) {
                            showGenericError(context, error);
                          }
                        } finally {
                          setState(() {
                            _isNoteSubmitting = false;
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
        SliverList.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final note = widget.document.notes.elementAt(index);
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Html(
                    data: markdownToHtml(note.note!),
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
                          DateFormat.yMMMd(
                                  Localizations.localeOf(context).toString())
                              .addPattern('\u2014')
                              .add_jm()
                              .format(note.created!),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(128),
                                  ),
                        ),
                      IconButton(
                        tooltip: S.of(context)!.delete,
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<DocumentDetailsCubit>().deleteNote(note);
                        },
                      ),
                    ],
                  ),
                ],
              ).padded(16),
            );
          },
          itemCount: widget.document.notes.length,
        ),
      ],
    );
  }
}
