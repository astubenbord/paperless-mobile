import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class OwnerFormField extends StatelessWidget {
  final String name;
  final Map<int, UserModel> users;
  final IdQueryParameter? initialValue;
  final void Function(IdQueryParameter?)? onChanged;

  const OwnerFormField({
    super.key,
    required this.name,
    required this.users,
    this.initialValue,
    this.onChanged,
  });

  String _displayName(UserModel user) {
    return user.fullName ?? user.username;
  }

  String _buildText(BuildContext context, IdQueryParameter? value) {
    return switch (value) {
      UnsetIdQueryParameter() => '',
      NotAssignedIdQueryParameter() => S.of(context)!.notAssigned,
      AnyAssignedIdQueryParameter() => S.of(context)!.anyAssigned,
      SetIdQueryParameter(id: var id) =>
        users[id] != null ? _displayName(users[id]!) : '',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return FormBuilderField<IdQueryParameter>(
      name: name,
      initialValue: initialValue,
      onChanged: onChanged,
      builder: (field) {
        final controller = TextEditingController(
          text: _buildText(context, field.value),
        );
        return Container(
          margin: const EdgeInsets.only(top: 6),
          child: TextField(
            controller: controller,
            readOnly: true,
            onTap: () => _showOwnerPicker(context, field),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline),
              labelText: 'Owner',
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          field.didChange(const UnsetIdQueryParameter()),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showOwnerPicker(
    BuildContext context,
    FormFieldState<IdQueryParameter> field,
  ) async {
    final result = await showModalBottomSheet<IdQueryParameter>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Owner',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: Text(S.of(context)!.notAssigned),
                onTap: () => Navigator.pop(
                    context, const NotAssignedIdQueryParameter()),
              ),
              ...users.values.map(
                (user) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_displayName(user)),
                  subtitle: user.fullName != null
                      ? Text(user.username)
                      : null,
                  selected: field.value is SetIdQueryParameter &&
                      (field.value as SetIdQueryParameter).id == user.id,
                  onTap: () => Navigator.pop(
                      context, SetIdQueryParameter(id: user.id)),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      field.didChange(result);
    }
  }
}
