import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/api/extensions/cached_query_extensions.dart';
import 'package:paperless_mobile/api/models/document.dart';
import 'package:paperless_mobile/core/repository/user_repository.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class DocumentPermissionsWidget extends StatefulWidget {
  final Document document;
  const DocumentPermissionsWidget({super.key, required this.document});

  @override
  State<DocumentPermissionsWidget> createState() =>
      _DocumentPermissionsWidgetState();
}

class _DocumentPermissionsWidgetState extends State<DocumentPermissionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: ExpansionTileThemeData(
          tilePadding: EdgeInsets.symmetric(horizontal: 8.0),
          childrenPadding: const EdgeInsets.only(left: 16.0),
        ),
      ),
      child: SliverList.list(
        children: [
          if (widget.document.owner != null)
            QueryBuilder(
              query: context.read<UserRepository>().getByIdQuery(
                widget.document.owner!,
              ),
              builder: (context, state) {
                if (state.isLoadingInitial) {
                  return DetailsItemSkeleton(label: S.of(context)!.owner);
                }
                if (state.isError) {
                  return Center(
                    child: Text(S.of(context)!.couldNotLoadPermissions),
                  );
                }
                final data = state.data!;

                return DetailsItem.text(
                  data.username,
                  label: S.of(context)!.owner,
                  context: context,
                );
              },
            ),
          // QueryBuilder(
          //   query: context.read<UserRepository>().getAllQuery(),
          //   builder: (context, state) {
          //     return ExpansionTile(
          //       title: Text('View'),
          //       children: [
          //         for (final userId
          //             in widget.document.permissions?.view?.users ?? [])
          //           state.isLoading
          //               ? Skeletonizer(
          //                   child: ListTile(title: Text(BoneMock.words(1))),
          //                 )
          //               : ListTile(
          //                   title: Text(
          //                     state.data
          //                             ?.firstWhere((u) => u.id == userId)
          //                             .username ??
          //                         '',
          //                   ),
          //                 ),
          //       ],
          //     );
          //   },
          // ),
          // QueryBuilder(
          //   query: context.read<UserRepository>().getAllQuery(),
          //   builder: (context, state) {
          //     return ExpansionTile(
          //       title: Text('Change'),
          //       children: [
          //         for (final userId
          //             in widget.document.permissions?.change?.users ?? [])
          //           state.isLoading
          //               ? Skeletonizer(
          //                   child: ListTile(title: Text(BoneMock.words(1))),
          //                 )
          //               : ListTile(
          //                   title: Text(
          //                     state.data
          //                             ?.firstWhere((u) => u.id == userId)
          //                             .username ??
          //                         '',
          //                   ),
          //                 ),
          //       ],
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}
