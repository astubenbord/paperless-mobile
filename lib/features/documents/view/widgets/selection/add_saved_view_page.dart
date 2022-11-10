import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/features/documents/model/document_filter.dart';
import 'package:paperless_mobile/features/documents/model/saved_view.model.dart';
import 'package:paperless_mobile/generated/l10n.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class AddSavedViewPage extends StatefulWidget {
  final DocumentFilter currentFilter;
  const AddSavedViewPage({super.key, required this.currentFilter});

  @override
  State<AddSavedViewPage> createState() => _AddSavedViewPageState();
}

class _AddSavedViewPageState extends State<AddSavedViewPage> {
  static const fkName = 'name';
  static const fkShowOnDashboard = 'show_on_dashboard';
  static const fkShowInSidebar = 'show_in_sidebar';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).savedViewCreateNewLabel),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Tooltip(
              child: const Icon(Icons.info_outline),
              message: S.of(context).savedViewCreateTooltipText,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        onPressed: () => _onCreate(context),
        label: Text(S.of(context).genericActionCreateLabel),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              FormBuilderTextField(
                name: fkName,
                validator: FormBuilderValidators.required(),
                decoration: InputDecoration(
                  label: Text(S.of(context).savedViewNameLabel),
                ),
              ),
              FormBuilderCheckbox(
                name: fkShowOnDashboard,
                initialValue: false,
                title: Text(S.of(context).savedViewShowOnDashboardLabel),
              ),
              FormBuilderCheckbox(
                name: fkShowInSidebar,
                initialValue: false,
                title: Text(S.of(context).savedViewShowInSidebarLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCreate(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      Navigator.pop(
        context,
        SavedView.fromDocumentFilter(
          widget.currentFilter,
          name: _formKey.currentState?.value[fkName] as String,
          showOnDashboard:
              _formKey.currentState?.value[fkShowOnDashboard] as bool,
          showInSidebar: _formKey.currentState?.value[fkShowInSidebar] as bool,
        ),
      );
    }
  }
}
