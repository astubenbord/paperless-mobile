import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class InboxEmptyWidget extends StatelessWidget {
  const InboxEmptyWidget({
    Key? key,
    required GlobalKey<RefreshIndicatorState> emptyStateRefreshIndicatorKey,
  })  : _emptyStateRefreshIndicatorKey = emptyStateRefreshIndicatorKey,
        super(key: key);

  final GlobalKey<RefreshIndicatorState> _emptyStateRefreshIndicatorKey;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _emptyStateRefreshIndicatorKey,
      onRefresh: () => context.read<InboxCubit>().loadInbox(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.of(context).inboxPageNoNewDocumentsText),
            TextButton(
              onPressed: () =>
                  _emptyStateRefreshIndicatorKey.currentState?.show(),
              child: Text(S.of(context).inboxPageNoNewDocumentsRefreshLabel),
            ),
          ],
        ),
      ),
    );
  }
}
