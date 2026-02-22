import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/widgets/form_fields/fullscreen_selection_form.dart';
import 'package:paperless_mobile/core/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/document_bulk_action/cubit/document_bulk_action_cubit.dart';
import 'package:paperless_mobile/features/document_bulk_action/view/widgets/confirm_bulk_modify_tags_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class FullscreenBulkEditTagsWidget extends StatefulWidget {
  const FullscreenBulkEditTagsWidget({super.key});

  @override
  State<FullscreenBulkEditTagsWidget> createState() =>
      _FullscreenBulkEditTagsWidgetState();
}

class _FullscreenBulkEditTagsWidgetState
    extends State<FullscreenBulkEditTagsWidget> {
  final TextEditingController _controller = TextEditingController();

  /// Tags shared by all documents
  late final List<int> _sharedTags;

  /// Tags not assigned to at least one document in the selection
  late final List<int> _nonSharedTags;

  final List<int> _addTags = [];
  final List<int> _removeTags = [];
  late List<int> _filteredTags;

  @override
  void initState() {
    super.initState();
    final state = context.read<DocumentBulkActionCubit>().state;
    final labels = context.read<LabelRepository>();
    _sharedTags = state.selection
        .map((e) => e.tags)
        .map((e) => e.toSet())
        .fold(
          labels.tags.values.map((e) => e.id!).toSet(),
          (previousValue, element) => previousValue.intersection(element),
        )
        .toList();
    _nonSharedTags = state.selection
        .map((e) => e.tags)
        .flattened
        .toSet()
        .difference(_sharedTags.toSet())
        .toList();
    _filteredTags = labels.tags.keys.toList();
    _controller.addListener(() {
      setState(() {
        _filteredTags = labels.tags.values
            .where((e) =>
                e.name.normalized().contains(_controller.text.normalized()))
            .map((e) => e.id!)
            .toList();
      });
    });
  }

  List<int> get _assignedTags => [..._sharedTags, ..._nonSharedTags];

  @override
  Widget build(BuildContext context) {
    final labelRepository = context.watch<LabelRepository>();
    return BlocBuilder<DocumentBulkActionCubit, DocumentBulkActionState>(
      builder: (context, state) {
        return FullscreenSelectionForm(
          controller: _controller,
          floatingActionButton: _addTags.isNotEmpty || _removeTags.isNotEmpty
              ? FloatingActionButton.extended(
                  heroTag: "fab_fullscreen_bulk_edit_tags",
                  label: Text(S.of(context)!.apply),
                  icon: const Icon(Icons.done),
                  onPressed: _submit,
                )
              : null,
          hintText: S.of(context)!.startTyping,
          leadingIcon: const Icon(Icons.label_outline),
          selectionBuilder: (context, index) {
            return _buildTagOption(
              _filteredTags[index],
              labelRepository.tags,
            );
          },
          selectionCount: _filteredTags.length,
        );
      },
    );
  }

  Widget _buildTagOption(int id, Map<int, Tag> options) {
    Widget? icon;
    if (_sharedTags.contains(id) && !_removeTags.contains(id)) {
      // Tag is assigned to all documents and not marked for removal
      // => will remain assigned
      icon = const Icon(Icons.done);
    } else if (_addTags.contains(id)) {
      // tag is marked to be added
      icon = const Icon(Icons.done);
    } else if (_nonSharedTags.contains(id) && !_removeTags.contains(id)) {
      // Tag is neither shared among all documents, nor marked to be removed or
      // added but assigned to at least one document
      icon = const Icon(Icons.remove);
    }

    return ListTile(
      title: Text(options[id]!.name),
      trailing: icon,
      leading: CircleAvatar(
        backgroundColor: options[id]!.color,
        foregroundColor: options[id]!.textColor,
        child: options[id]!.isInboxTag ? const Icon(Icons.inbox) : null,
      ),
      onTap: () {
        if (_addTags.contains(id)) {
          setState(() {
            _addTags.remove(id);
          });
          if (_assignedTags.contains(id)) {
            setState(() {
              _removeTags.add(id);
            });
          }
        } else if (_removeTags.contains(id)) {
          setState(() {
            _removeTags.remove(id);
          });
          if (!_sharedTags.contains(id)) {
            setState(() {
              _addTags.add(id);
            });
          }
        } else {
          if (_sharedTags.contains(id)) {
            setState(() {
              _removeTags.add(id);
            });
          } else {
            setState(() {
              _addTags.add(id);
            });
          }
        }
      },
    );
  }

  Future<void> _submit() async {
    if (_addTags.isNotEmpty || _removeTags.isNotEmpty) {
      final bloc = context.read<DocumentBulkActionCubit>();
      final labelRepository = context.read<LabelRepository>();
      final addNames = _addTags
          .where((value) => labelRepository.tags.containsKey(value))
          .map((value) => "\"${labelRepository.tags[value]!.name}\"")
          .toList();
      final removeNames = _removeTags
          .where((value) => labelRepository.tags.containsKey(value))
          .map((value) => "\"${labelRepository.tags[value]!.name}\"")
          .toList();
      final shouldPerformAction = await showDialog<bool>(
            context: context,
            builder: (context) => ConfirmBulkModifyTagsDialog(
              selectionCount: bloc.state.selection.length,
              addTags: addNames,
              removeTags: removeNames,
            ),
          ) ??
          false;
      if (shouldPerformAction) {
        bloc.bulkModifyTags(
          removeTagIds: _removeTags,
          addTagIds: _addTags,
        );
        if (mounted) context.pop();
      }
    }
  }
}
