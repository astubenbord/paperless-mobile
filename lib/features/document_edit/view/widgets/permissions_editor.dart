import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/user_repository.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class PermissionsEditorSection extends StatefulWidget {
  final int? initialOwner;
  final Permissions? initialPermissions;
  final ValueChanged<int?> onOwnerChanged;
  final ValueChanged<Permissions?> onPermissionsChanged;

  const PermissionsEditorSection({
    super.key,
    required this.initialOwner,
    required this.initialPermissions,
    required this.onOwnerChanged,
    required this.onPermissionsChanged,
  });

  @override
  State<PermissionsEditorSection> createState() =>
      _PermissionsEditorSectionState();
}

class _PermissionsEditorSectionState extends State<PermissionsEditorSection> {
  late int? _selectedOwner;
  late Permissions? _permissions;

  @override
  void initState() {
    super.initState();
    _selectedOwner = widget.initialOwner;
    _permissions = widget.initialPermissions;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserRepository, UserRepositoryState>(
      builder: (context, userState) {
        final users = userState.users;
        if (users.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.permissionsEditor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Owner dropdown
            DropdownButtonFormField<int?>(
              decoration: InputDecoration(
                labelText: S.of(context)!.owner,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              initialValue: _selectedOwner,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('-'),
                ),
                ...users.values.map((user) => DropdownMenuItem<int?>(
                      value: user.id,
                      child: Text(user.fullName ?? user.username),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedOwner = value);
                widget.onOwnerChanged(value);
              },
            ),
            const SizedBox(height: 16),
            // View permissions
            if (_permissions != null) ...[
              _buildPermissionRow(
                S.of(context)!.viewPermission,
                _permissions!.view,
                users,
                (updated) {
                  setState(() {
                    _permissions = Permissions(
                      view: updated,
                      change: _permissions!.change,
                    );
                  });
                  widget.onPermissionsChanged(_permissions);
                },
              ),
              const SizedBox(height: 8),
              _buildPermissionRow(
                S.of(context)!.changePermission,
                _permissions!.change,
                users,
                (updated) {
                  setState(() {
                    _permissions = Permissions(
                      view: _permissions!.view,
                      change: updated,
                    );
                  });
                  widget.onPermissionsChanged(_permissions);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPermissionRow(
    String label,
    UsersAndGroupsPermissions perms,
    Map<int, UserModel> allUsers,
    ValueChanged<UsersAndGroupsPermissions> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label - ${S.of(context)!.users}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...perms.users.map((userId) {
              final user = allUsers[userId];
              return Chip(
                label: Text(user?.username ?? 'User $userId'),
                onDeleted: () {
                  final updated = UsersAndGroupsPermissions(
                    users: perms.users.where((id) => id != userId).toList(),
                    groups: perms.groups,
                  );
                  onChanged(updated);
                },
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(S.of(context)!.addCorrespondent.split(' ').first),
              onPressed: () {
                _showUserPicker(
                  allUsers,
                  perms.users,
                  (selectedId) {
                    final updated = UsersAndGroupsPermissions(
                      users: [...perms.users, selectedId],
                      groups: perms.groups,
                    );
                    onChanged(updated);
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showUserPicker(
    Map<int, UserModel> allUsers,
    List<int> existingIds,
    ValueChanged<int> onSelected,
  ) {
    final available = allUsers.values
        .where((u) => !existingIds.contains(u.id))
        .toList();

    if (available.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(S.of(context)!.users),
        children: available.map((user) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              onSelected(user.id);
            },
            child: Text(user.fullName ?? user.username),
          );
        }).toList(),
      ),
    );
  }
}
