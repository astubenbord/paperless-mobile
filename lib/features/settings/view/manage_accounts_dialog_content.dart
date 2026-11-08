import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/users/view/widgets/user_account_list_tile.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/auth_route.dart';

class ManageAccountsDialogContent extends StatelessWidget {
  const ManageAccountsDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedInUserId = context.loggedInAppUserId$;
    // This is one of the few places where the currentLoggedInUser can be null
    // (exactly after loggin out as the current user to be precise).

    if (loggedInUserId == null) {
      return const SizedBox.shrink();
    }

    final currentUser = context.loggedInUser$;
    return BlocBuilder<LocalStore, LocalStoreState>(
      builder: (context, state) {
        final accounts = state.localUserData;
        final userIds = accounts.keys;
        final otherAccountIds = userIds
            .whereNot((element) => element == loggedInUserId)
            .toList();
        return SimpleDialog(
          insetPadding: const EdgeInsets.all(24),
          contentPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Stack(
            alignment: Alignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CloseButton(),
              ),
              Center(child: Text(S.of(context)!.accounts)),
            ],
          ),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: UserAccountListTile(
                serverUrl: currentUser.serverUrl,
                username: currentUser.profile.uiSettings.user.username,
                displayName: currentUser.displayName,
                trailing: IconButton(
                  tooltip: S.of(context)!.removeUserAndLogOut,
                  icon: const Icon(Icons.person_remove_outlined),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<AuthenticationCubit>().logout(true);
                  },
                ),
              ),
            ).paddedOnly(bottom: 4),
            Column(
              spacing: 4,
              children: [
                for (int index = 0; index < otherAccountIds.length; index++)
                  Builder(
                    builder: (context) {
                      final user = accounts[otherAccountIds[index]];
                      if (user == null) {
                        return const SizedBox.shrink();
                      }
                      return Tooltip(
                        message: S.of(context)!.switchAccount,
                        child: UserAccountListTile(
                          serverUrl: user.serverUrl,
                          username: user.username,
                          displayName: user.displayName,
                          onTap: () {
                            _onSwitchAccount(
                              context,
                              loggedInUserId,
                              otherAccountIds[index],
                            );
                          },
                          trailing: IconButton(
                            tooltip: S.of(context)!.removeUser,
                            icon: const Icon(Icons.person_remove_outlined),
                            onPressed: () {
                              context.read<AuthenticationCubit>().removeAccount(
                                otherAccountIds[index],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const Divider(),
            ListTile(
              title: Text(S.of(context)!.addAccount),
              leading: const Icon(Icons.person_add),
              onTap: () {
                _onAddAccount(context, loggedInUserId);
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              title: Text(S.of(context)!.logout),
              leading: const Icon(Icons.logout),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthenticationCubit>().logout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onAddAccount(BuildContext context, String currentUser) async {
    Navigator.of(context).pop();
    const AuthRoute().push(context);
  }

  void _onSwitchAccount(
    BuildContext context,
    String currentUser,
    String newUser,
  ) async {
    if (currentUser == newUser) return;

    Navigator.of(context).pop();
    await context.read<AuthenticationCubit>().switchAccount(newUser);
  }
}
