import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/form_fields/fullscreen_selection_form.dart';
import 'package:paperless_mobile/core/extensions/dart_extensions.dart';
import 'package:paperless_mobile/features/document_bulk_action/view/widgets/confirm_bulk_modify_label_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class FullscreenBulkEditLabelPage extends StatefulWidget {
  final String hintText;
  final Map<int, Label> options;
  final List<DocumentModel> selection;
  final int? Function(DocumentModel document) labelMapper;
  final Widget leadingIcon;
  final void Function(int? id) onSubmit;
  final String Function(int count) removeMessageBuilder;
  final String Function(int count, String name) assignMessageBuilder;

  FullscreenBulkEditLabelPage({
    super.key,
    required this.options,
    required this.selection,
    required this.labelMapper,
    required this.leadingIcon,
    required this.hintText,
    required this.onSubmit,
    required this.removeMessageBuilder,
    required this.assignMessageBuilder,
  }) : assert(selection.isNotEmpty);

  @override
  State<FullscreenBulkEditLabelPage> createState() =>
      _FullscreenBulkEditLabelPageState();
}

class _FullscreenBulkEditLabelPageState<T extends Label>
    extends State<FullscreenBulkEditLabelPage> {
  final _controller = TextEditingController();

  LabelSelection? _selection;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
    if (_initialValues.length == 1 && _initialValues.first != null) {
      _selection = LabelSelection(_initialValues.first);
    }
  }

  List<int?> get _initialValues =>
      widget.selection.map(widget.labelMapper).toSet().toList();

  Iterable<int> _generateOrderedLabels() sync* {
    final availableValues = widget.options.values
        .where(
            (e) => e.name.normalized().contains(_controller.text.normalized()))
        .map((e) => e.id!)
        .toSet();
    for (var label
        in _initialValues.toSet().intersection(availableValues.toSet())) {
      if (label != null) {
        yield label;
      }
    }
    for (final id
        in availableValues.whereNot((e) => _initialValues.contains(e))) {
      yield id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _generateOrderedLabels();
    final hideFab = _selection == null ||
        (_initialValues.length == 1 &&
            _selection?.label == _initialValues.first);
    return FullscreenSelectionForm(
      controller: _controller,
      hintText: widget.hintText,
      leadingIcon: widget.leadingIcon,
      selectionBuilder: (context, index) =>
          _buildItem(widget.options[labels.elementAt(index)]!),
      selectionCount: labels.length,
      floatingActionButton: !hideFab
          ? FloatingActionButton.extended(
              heroTag: "fab_fullscreen_bulk_edit_label",
              onPressed: _onSubmit,
              label: Text(S.of(context)!.apply),
              icon: const Icon(Icons.done),
            )
          : null,
    );
  }

  Widget _buildItem(Label label) {
    Widget? trailingIcon;
    if (_initialValues.length > 1 &&
        _selection == null &&
        _initialValues.contains(label.id)) {
      trailingIcon = const Icon(Icons.remove);
    } else if (_selection?.label == label.id) {
      trailingIcon = const Icon(Icons.done);
    }
    return ListTile(
      title: Text(label.name),
      trailing: trailingIcon,
      onTap: () {
        if (_selection?.label == label.id) {
          setState(() {
            _selection = LabelSelection(null);
          });
        } else {
          setState(() {
            _selection = LabelSelection(label.id);
          });
        }
      },
    );
  }

  Future<void> _onSubmit() async {
    if (_selection == null) {
      context.pop();
    } else {
      bool shouldPerformAction;
      if (_selection!.label == null) {
        shouldPerformAction = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmBulkModifyLabelDialog(
                content: widget.removeMessageBuilder(widget.selection.length),
              ),
            ) ??
            false;
      } else {
        final labelName = widget.options[_selection!.label]!.name;
        shouldPerformAction = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmBulkModifyLabelDialog(
                content: widget.assignMessageBuilder(
                  widget.selection.length,
                  '"$labelName"',
                ),
              ),
            ) ??
            false;
      }
      if (shouldPerformAction) {
        widget.onSubmit(_selection!.label);
        if (mounted) context.pop();
      }
    }
  }
}

class LabelSelection {
  final int? label;

  LabelSelection(this.label);
}
