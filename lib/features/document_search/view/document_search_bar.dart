import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/features/document_search/cubit/document_search_cubit.dart';
import 'package:paperless_mobile/features/document_search/view/document_search_page.dart';
import 'package:paperless_mobile/features/settings/view/manage_accounts_page.dart';
import 'package:paperless_mobile/features/settings/view/widgets/user_avatar.dart';
import 'package:paperless_mobile/features/sharing/cubit/receive_share_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DocumentSearchBar extends StatefulWidget {
  const DocumentSearchBar({super.key});

  @override
  State<DocumentSearchBar> createState() => _DocumentSearchBarState();
}

class _DocumentSearchBarState extends State<DocumentSearchBar> {
  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 200),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      middleColor: Theme.of(context).colorScheme.surfaceContainer,
      openColor: Theme.of(context).colorScheme.surface,
      closedColor: Theme.of(context).colorScheme.surfaceContainer,
      closedShape: const StadiumBorder(),
      closedBuilder: (_, action) {
        return InkWell(
          onTap: action,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
              minWidth: 360,
              maxHeight: 56,
              minHeight: 56,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: ListenableBuilder(
                            listenable:
                                context.read<ConsumptionChangeNotifier>(),
                            builder: (context, child) {
                              return Badge(
                                isLabelVisible: context
                                    .read<ConsumptionChangeNotifier>()
                                    .pendingFiles
                                    .isNotEmpty,
                                backgroundColor: Theme.of(context).colorScheme.error,
                                smallSize: 10,
                                child: const Icon(Icons.menu),
                              );
                            },
                          ),
                          onPressed: Scaffold.of(context).openDrawer,
                        ),
                        Flexible(
                          child: Text(
                            S.of(context)!.searchDocuments,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildUserAvatar(context),
              ],
            ),
          ),
        );
      },
      openBuilder: (_, action) {
        return Provider(
          create: (_) => DocumentSearchCubit(
            context.read(),
            context.read(),
            Hive.box<LocalUserAppState>(HiveBoxes.localUserAppState)
                .get(context.read<LocalUserAccount>().id)!,
            context.read(),
          ),
          child: const DocumentSearchPage(),
        );
      },
    );
  }

  IconButton _buildUserAvatar(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(6),
      icon: UserAvatar(account: context.watch<LocalUserAccount>()),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => const ManageAccountsPage(),
        );
      },
    );
  }
}
