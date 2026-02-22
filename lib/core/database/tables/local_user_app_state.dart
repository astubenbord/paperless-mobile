import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/model/view_type.dart';

part 'local_user_app_state.g.dart';

///
/// Object used for the persistence of app state, e.g. set filters,
/// search history and implicit settings.
///
@HiveType(typeId: HiveTypeIds.localUserAppState)
class LocalUserAppState extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  DocumentFilter currentDocumentFilter;

  @HiveField(2)
  List<String> documentSearchHistory;

  @HiveField(3)
  ViewType documentsPageViewType;

  @HiveField(4)
  ViewType savedViewsViewType;

  @HiveField(5)
  ViewType documentSearchViewType;

  LocalUserAppState({
    required this.userId,
    this.currentDocumentFilter = const DocumentFilter(),
    this.documentSearchHistory = const [],
    this.documentsPageViewType = ViewType.list,
    this.documentSearchViewType = ViewType.list,
    this.savedViewsViewType = ViewType.list,
  });

  static LocalUserAppState get current {
    final currentLocalUserId =
        Hive.globalSettings
            .loggedInUserId!;
    return Hive.box<LocalUserAppState>(HiveBoxes.localUserAppState)
        .get(currentLocalUserId)!;
  }
}
