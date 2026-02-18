import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/widgets/hint_card.dart';
import 'package:paperless_mobile/features/saved_view/cubit/saved_view_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

const _fkName = 'name';
const _fkShowOnDashboard = 'show_on_dashboard';
const _fkShowInSidebar = 'show_in_sidebar';

class AddSavedViewPage extends StatefulWidget {
  final DocumentFilter? initialFilter;
  final bool? showOnDashboard;
  final bool? showInSidebar;
  const AddSavedViewPage({
    super.key,
    this.initialFilter,
    this.showOnDashboard,
    this.showInSidebar,
  });

  @override
  State<AddSavedViewPage> createState() => _AddSavedViewPageState();
}

class _AddSavedViewPageState extends State<AddSavedViewPage> {
  final _savedViewFormKey = GlobalKey<FormBuilderState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.newView),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_add_saved_view_page",
        icon: const Icon(Icons.add),
        onPressed: () => _onCreate(context),
        label: Text(S.of(context)!.create),
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
                    initialValue: widget.showOnDashboard ?? false,
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
                    initialValue: widget.showInSidebar ?? false,
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
            //TODO: INTL or remove
            HintCard(
              hintText:
                  "Saved views can currently only be edited by changing the "
                  "document filter. Therefore, go to the documents page, select "
                  "this view, add the filters you want this view to have and "
                  "save it by pressing 'Save changes' in the view menu.",
            ),
          ],
        ),
      ),
    );
  }

  void _onCreate(BuildContext context) async {
    if (_savedViewFormKey.currentState?.saveAndValidate() ?? false) {
      final cubit = context.read<SavedViewCubit>();
      var savedView = SavedView.fromDocumentFilter(
        widget.initialFilter ?? const DocumentFilter(),
        name: _savedViewFormKey.currentState?.value[_fkName] as String,
        showOnDashboard:
            _savedViewFormKey.currentState?.value[_fkShowOnDashboard] as bool,
        showInSidebar:
            _savedViewFormKey.currentState?.value[_fkShowInSidebar] as bool,
      );
      final router = GoRouter.of(context);
      await cubit.add(
        savedView,
      );
      router.pop();
    }
  }
}
