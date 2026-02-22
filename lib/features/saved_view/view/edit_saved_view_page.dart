import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

const _fkName = 'name';
const _fkShowOnDashboard = 'show_on_dashboard';
const _fkShowInSidebar = 'show_in_sidebar';

class EditSavedViewPage extends StatefulWidget {
  final SavedView savedView;
  const EditSavedViewPage({
    super.key,
    required this.savedView,
  });

  @override
  State<EditSavedViewPage> createState() => _EditSavedViewPageState();
}

class _EditSavedViewPageState extends State<EditSavedViewPage> {
  final _savedViewFormKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.editView),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_edit_saved_view_page",
        icon: const Icon(Icons.save),
        onPressed: () => _onCreate(context),
        label: Text(S.of(context)!.saveChanges),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FormBuilder(
              key: _savedViewFormKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    initialValue: widget.savedView.name,
                    name: _fkName,
                    enableSuggestions: true,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return S.of(context)!.thisFieldIsRequired;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      label: Text(S.of(context)!.name),
                    ),
                  ),
                  FormBuilderField<bool>(
                    name: _fkShowOnDashboard,
                    initialValue: widget.savedView.showOnDashboard,
                    builder: (field) {
                      return CheckboxListTile(
                        value: field.value,
                        title: Text(S.of(context)!.showOnDashboard),
                        onChanged: (value) => field.didChange(value),
                      );
                    },
                  ),
                  FormBuilderField<bool>(
                    name: _fkShowInSidebar,
                    initialValue: widget.savedView.showInSidebar,
                    builder: (field) {
                      return CheckboxListTile(
                        value: field.value,
                        title: Text(S.of(context)!.showInSidebar),
                        onChanged: (value) => field.didChange(value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCreate(BuildContext context) async {
    if (_savedViewFormKey.currentState?.saveAndValidate() ?? false) {
      final cubit = context.read<SavedViewCubit>();
      var savedView = widget.savedView.copyWith(
        name: _savedViewFormKey.currentState!.value[_fkName],
        showInSidebar: _savedViewFormKey.currentState!.value[_fkShowInSidebar],
        showOnDashboard:
            _savedViewFormKey.currentState!.value[_fkShowOnDashboard],
      );
      final router = GoRouter.of(context);
      await cubit.update(savedView);
      router.pop();
    }
  }
}
