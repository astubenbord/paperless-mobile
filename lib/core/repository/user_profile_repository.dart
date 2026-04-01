import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/store/slices/user_profile.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';

class SessionData {
  final int apiVersion;
  final UserProfile profile;

  const SessionData({required this.apiVersion, required this.profile});
}

class SessionDataRepository {
  final PaperlessUserApi _userApi;
  final PaperlessServerStatsApi _serverStatsApi;

  SessionDataRepository(this._userApi, this._serverStatsApi);

  Query<SessionData> userProfileQuery(String localUserId) {
    return Query(
      key: 'user_profile/$localUserId',
      queryFn: () async {
        try {
          final [
            profile as Profile,
            uiSettings as UiSettingsView,
          ] = await Future.wait([
            _userApi.getProfile(),
            _userApi.getUiSettings(),
          ]);
          final serverStats = await _serverStatsApi.getServerInformation();
          return SessionData(
            apiVersion: serverStats.apiVersion,
            profile: UserProfile(profile: profile, uiSettings: uiSettings),
          );
        } catch (error, stackTrace) {
          logger.fe(
            'An error occurred trying to get the user profile',
            className: runtimeType.toString(),
            methodName: 'userProfileQuery',
            error: error,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      },
    );
  }
}
