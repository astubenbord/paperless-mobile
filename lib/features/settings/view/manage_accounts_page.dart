import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/features/users/view/widgets/user_account_list_tile.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/routing/routes/add_account_route.dart';
import 'package:provider/provider.dart';

class ManageAccountsPage extends StatelessWidget {
  const ManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, globalSettings) {
        // // This is one of the few places where the currentLoggedInUser can be null
        // // (exactly after loggin out as the current user to be precise).

        return ValueListenableBuilder(
          valueListenable: Hive.localUserAccountBox.listenable(),
          builder: (context, box, _) {
            if (globalSettings.loggedInUserId == null) {
              return const SizedBox.shrink();
            }
            final userIds = box.keys.toList().cast<String>();
            final otherAccounts = userIds
                .whereNot((element) => element == globalSettings.loggedInUserId)
                .toList();
            return SimpleDialog(
              insetPadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.all(8),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              children: [
                Card(
                  child: UserAccountListTile(
                    account: box.get(globalSettings.loggedInUserId!)!,
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 0,
                          child: ListTile(
                            title: Text(S.of(context)!.logout),
                            leading: const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 0) {
                          Navigator.of(context).pop();
                          await context
                              .read<AuthenticationCubit>()
                              .logout(true);
                        }
                      },
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (int index = 0; index < otherAccounts.length; index++)
                      UserAccountListTile(
                        account: box.get(otherAccounts[index])!,
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                value: 0,
                                child: ListTile(
                                  title: Text(S.of(context)!.switchAccount),
                                  leading:
                                      const Icon(Icons.switch_account_rounded),
                                ),
                              ),
                              PopupMenuItem(
                                value: 1,
                                child: ListTile(
                                  title: Text(S.of(context)!.remove),
                                  leading: const Icon(
                                    Icons.person_remove,
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            ];
                          },
                          onSelected: (value) async {
                            if (value == 0) {
                              // Switch
                              _onSwitchAccount(
                                context,
                                globalSettings.loggedInUserId!,
                                otherAccounts[index],
                              );
                            } else if (value == 1) {
                              await context
                                  .read<AuthenticationCubit>()
                                  .removeAccount(otherAccounts[index]);
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const Divider(),
                ListTile(
                  title: Text(S.of(context)!.addAccount),
                  leading: const Icon(Icons.person_add),
                  onTap: () {
                    _onAddAccount(context, globalSettings.loggedInUserId!);
                  },
                ),
                //TODO: Implement permission/user settings at some point...
                // if (context.watch<LocalUserAccount>().hasMultiUserSupport)
                //   ListTile(
                //     leading: const Icon(Icons.admin_panel_settings),
                //     title: Text(S.of(context)!.managePermissions),
                //   ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onAddAccount(BuildContext context, String currentUser) async {
    Navigator.of(context).pop();
    const AddAccountRoute().push<String>(context);
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
