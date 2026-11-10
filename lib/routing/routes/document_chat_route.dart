import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_mobile/features/document_chat/cubit/document_chat_cubit.dart';
import 'package:paperless_mobile/features/document_chat/view/document_chat_page.dart';
import 'package:paperless_mobile/routing/navigation_keys.dart';

import 'shells/authenticated_route.dart';

class DocumentChatRoute extends GoRouteData with $DocumentChatRoute {
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      outerShellNavigatorKey;

  final int? documentId;
  final String? documentTitle;

  const DocumentChatRoute({this.documentId, this.documentTitle});

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (context) =>
          DocumentChatCubit(context.read(), documentId: documentId),
      child: DocumentChatPage(documentTitle: documentTitle),
    );
  }
}
