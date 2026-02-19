import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/app_drawer/view/app_drawer.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/core/theme.dart';

class ScaffoldWithNavigationBar extends StatefulWidget {
  final UserModel authenticatedUser;
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavigationBar({
    super.key,
    required this.authenticatedUser,
    required this.navigationShell,
  });

  @override
  State<ScaffoldWithNavigationBar> createState() =>
      ScaffoldWithNavigationBarState();
}

class ScaffoldWithNavigationBarState extends State<ScaffoldWithNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: buildOverlayStyle(theme),
      child: Scaffold(
        drawer: const AppDrawer(),
        bottomNavigationBar: NavigationBar(
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: S.of(context)!.home,
            ),
            _toggleDestination(
              NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon: const Icon(Icons.description_rounded),
                label: S.of(context)!.documents,
              ),
              disableWhen: !widget.authenticatedUser.canViewDocuments,
            ),
            _toggleDestination(
              NavigationDestination(
                icon: const Icon(Icons.document_scanner_outlined),
                selectedIcon: const Icon(Icons.document_scanner_rounded),
                label: S.of(context)!.scanner,
              ),
              disableWhen: !widget.authenticatedUser.canCreateDocuments,
            ),
            _toggleDestination(
              NavigationDestination(
                icon: const Icon(Icons.sell_outlined),
                selectedIcon: const Icon(Icons.sell_rounded),
                label: S.of(context)!.labels,
              ),
              disableWhen: !widget.authenticatedUser.canViewAnyLabel,
            ),
            _toggleDestination(
              NavigationDestination(
                icon: Builder(
                  builder: (context) {
                    return BlocBuilder<InboxCubit, InboxState>(
                      builder: (context, state) {
                        return Badge.count(
                          isLabelVisible: state.itemsInInboxCount > 0,
                          count: state.itemsInInboxCount,
                          child: const Icon(Icons.inbox_outlined),
                        );
                      },
                    );
                  },
                ),
                selectedIcon: BlocBuilder<InboxCubit, InboxState>(
                  builder: (context, state) {
                    return Badge.count(
                      isLabelVisible: state.itemsInInboxCount > 0 &&
                          widget.authenticatedUser.canViewInbox,
                      count: state.itemsInInboxCount,
                      child: const Icon(Icons.inbox_rounded),
                    );
                  },
                ),
                label: S.of(context)!.inbox,
              ),
              disableWhen: !widget.authenticatedUser.canViewInbox,
            ),
          ],
        ),
        body: widget.navigationShell,
      ),
    );
  }

  Widget _toggleDestination(
    Widget destination, {
    required bool disableWhen,
  }) {
    final disabledColor = Theme.of(context).disabledColor;

    final disabledTheme = Theme.of(context).navigationBarTheme.copyWith(
          labelTextStyle: WidgetStatePropertyAll(
            Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: disabledColor),
          ),
          iconTheme: WidgetStatePropertyAll(
            Theme.of(context).iconTheme.copyWith(color: disabledColor),
          ),
        );
    if (disableWhen) {
      return AbsorbPointer(
        child: Theme(
          data: Theme.of(context).copyWith(navigationBarTheme: disabledTheme),
          child: destination,
        ),
      );
    }
    return destination;
  }
}
