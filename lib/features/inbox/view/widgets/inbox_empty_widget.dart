import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/inbox/bloc/inbox_cubit.dart';

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
      onRefresh: () => BlocProvider.of<InboxCubit>(context).loadInbox(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You do not have unseen documents.'),
            TextButton(
              onPressed: () =>
                  _emptyStateRefreshIndicatorKey.currentState?.show(),
              child: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
