import 'package:hive_ce/hive.dart';
import 'package:paperless_api/paperless_api.dart';

class PaperlessApiHiveTypeIds {
  PaperlessApiHiveTypeIds._();

  static const int idQueryParameter = 101;
  static const int tagsQuery = 102;
  static const int anyAssignedTagsQuery = 103;
  static const int tagIdQuery = 104;
  static const int includeTagIdQuery = 105;
  static const int idsTagsQuery = 106;
  static const int excludeTagIdQuery = 107;
  static const int sortField = 108;
  static const int sortOrder = 109;
  static const int absoluteDateRangeQuery = 110;
  static const int relativeDateRangeQuery = 111;
  static const int dateRangeUnit = 112;
  static const int unsetDateRangeQuery = 113;
  static const int textQuery = 114;
  static const int queryType = 115;
  static const int unsetIdQueryParameter = 116;
  static const int notAssignedIdQueryParameter = 117;
  static const int anyAssignedIdQueryParameter = 118;
  static const int setIdQueryParameter = 119;
  static const int notAssignedTagsQuery = 120;
  static const int userModelv3 = 121;
  static const int userPermissions = 122;
  static const int inheritedPermissions = 123;
  static const int groupModel = 124;
  static const int permissions = 125;
  static const int userModelv2 = 126;
  static const int usersAndGroupsPermissions = 127;
  static const int documentFilter = 128;
  static const int exactDateQuery = 129;
}

void registerPaperlessApiHiveTypeAdapters() {
  Hive.registerAdapter(DocumentFilterAdapter());
  // TagsQuery
  Hive.registerAdapter(AnyAssignedTagsQueryAdapter());
  Hive.registerAdapter(NotAssignedTagsQueryAdapter());
  Hive.registerAdapter(IdsTagsQueryAdapter());

  Hive.registerAdapter(SortFieldAdapter());
  Hive.registerAdapter(SortOrderAdapter());
  Hive.registerAdapter(AbsoluteDateRangeQueryAdapter());
  Hive.registerAdapter(RelativeDateRangeQueryAdapter());
  Hive.registerAdapter(DateRangeUnitAdapter());
  Hive.registerAdapter(UnsetDateRangeQueryAdapter());
  Hive.registerAdapter(ExactDateQueryAdapter());
  Hive.registerAdapter(TextQueryAdapter());
  Hive.registerAdapter(QueryTypeAdapter());
  // IdQueryParameter
  Hive.registerAdapter(SetIdQueryParameterAdapter());
  Hive.registerAdapter(UnsetIdQueryParameterAdapter());
  Hive.registerAdapter(AnyAssignedIdQueryParameterAdapter());
  Hive.registerAdapter(NotAssignedIdQueryParameterAdapter());
  // Users and permissions
  Hive.registerAdapter(UserModelV3Adapter());
  Hive.registerAdapter(UserModelV2Adapter());
  Hive.registerAdapter(GroupModelAdapter());
  Hive.registerAdapter(PermissionsAdapter());
}
