import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/store/encrypted_local_store.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:paperless_mobile/core/store/slices/user_credentials.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/logging/utils/redaction_utils.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/search_index/cubit/search_index_cubit.dart';
import 'package:paperless_mobile/features/search_index/search_index_channel.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final LocalAuthenticationService _localAuthService;
  final PaperlessUserApi _usersApi;
  final LocalStore _store;
  final EncryptedLocalStore _encryptedLocalStore;
  final SessionManager _sessionManager;
  final ConnectivityStatusService _connectivityService;
  final LocalNotificationService _notificationService;
  final SearchIndexChannel _searchIndexChannel;

  AuthenticationCubit(
    this._usersApi,
    this._sessionManager,
    this._connectivityService,
    this._localAuthService,
    this._notificationService,
    this._store,
    this._encryptedLocalStore,
    this._searchIndexChannel,
  ) : super(const Unauthenticated());

  Future<void> addUser({
    required String serverUrl,
    required String token,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) async {
    emit(const Authenticating());
    try {
      final userProfile = await _addUser(
        serverUrl,
        token,
        clientCertificate,
        additionalHeaders,
        _sessionManager,
      );

      final localUserId = _buildLocalUserId(userProfile, serverUrl);
      _store.setLoggedInAppUserId(localUserId);
      emit(Authenticated(localUserId: localUserId));
      logger.fd(
        'User ${redactUserId(localUserId)} successfully logged in.',
        className: runtimeType.toString(),
        methodName: 'addUser',
      );
    } catch (error, stackTrace) {
      logger.fe(
        "Failed to add user.",
        className: runtimeType.toString(),
        methodName: 'addUser',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        AuthenticationError(
          serverUrl: serverUrl,
          clientCertificate: clientCertificate,
          additionalHeaders: additionalHeaders,
          error: error,
        ),
      );
    }
  }

  /// Switches to another account if it exists.
  Future<void> switchAccount(String localUserId) async {
    emit(const SwitchingAccounts());
    final redactedId = redactUserId(localUserId);

    try {
      await FileService.instance.initialize();

      if (!_store.state.localUserData.containsKey(localUserId)) {
        logger.fw(
          'User $redactedId not registered.',
          className: runtimeType.toString(),
          methodName: 'switchAccount',
        );
        emit(const Unauthenticated(redirectToAccountSelection: true));
        return;
      }
      final localUserData = _store.state.localUserData[localUserId]!;

      if (localUserData.isBiometricAuthenticationEnabled) {
        final authenticated = await _localAuthService.authenticateLocalUser(
          "Authenticate to switch your account.",
        );
        if (!authenticated) {
          emit(VerifyingIdentity(userId: localUserId));
          return;
        }
      }

      final currentlyLoggedInUser = _store.state.loggedInAppUserId;
      if (currentlyLoggedInUser != localUserId) {
        await _notificationService.cancelUserNotifications(localUserId);
      }

      final credentialsExist = await _encryptedLocalStore.contains(localUserId);
      if (!credentialsExist) {
        logger.fw(
          "Credentials not found for $redactedId.",
          className: runtimeType.toString(),
          methodName: 'switchAccount',
        );
        emit(const Unauthenticated(redirectToAccountSelection: true));
        return;
      }
      final decryptedState = (await _encryptedLocalStore.read(localUserId))!;

      await _resetExternalState();
      _sessionManager.updateSettings(
        authToken: decryptedState.credentials.token,
        clientCertificate: decryptedState.credentials.clientCertificate,
        additionalHeaders: decryptedState.credentials.additionalHeaders,
        baseUrl: localUserData.serverUrl,
        broadcast: false,
      );

      _store.setLoggedInAppUserId(localUserId);

      final isPaperlessServerReachable =
          await _connectivityService.isPaperlessServerReachable(
            localUserData.serverUrl,
            decryptedState.credentials.clientCertificate,
            decryptedState.credentials.additionalHeaders,
          ) ==
          ReachabilityStatus.reachable;

      if (!isPaperlessServerReachable) {
        logger.fw(
          'Server not reachable during account switch for $redactedId.',
          className: runtimeType.toString(),
          methodName: 'switchAccount',
        );
        emit(ConnectionFailure(serverUrl: localUserData.serverUrl));
        return;
      }

      emit(Authenticated(localUserId: localUserId));
      logger.fd(
        'Switched to user $redactedId.',
        className: runtimeType.toString(),
        methodName: 'switchAccount',
      );
    } catch (error, stackTrace) {
      logger.fe(
        "Failed to switch to account $redactedId.",
        className: runtimeType.toString(),
        methodName: 'switchAccount',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const Unauthenticated(redirectToAccountSelection: true));
    }
  }

  Future<void> removeAccount(String userId) async {
    try {
      _store.removeUserData(userId);
      await _encryptedLocalStore.clear(userId);
      await FileService.instance.clearUserData(userId: userId);
      await _clearSearchIndex(userId);
      if (_store.state.localUserData.keys.isEmpty) {
        emit(const Unauthenticated(redirectToAccountSelection: false));
      }
    } catch (error, stackTrace) {
      logger.fe(
        "Failed to remove account ${redactUserId(userId)}.",
        className: runtimeType.toString(),
        methodName: 'removeAccount',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Restores the previous session if exists.
  Future<void> restoreSession([String? userId]) async {
    emit(const RestoringSession());
    final restoreSessionUserId = userId ?? _store.state.loggedInAppUserId;

    if (restoreSessionUserId == null ||
        !_store.state.localUserData.containsKey(restoreSessionUserId)) {
      logger.fd(
        "No session to restore.",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
      final otherAccountsExist = _store.state.localUserData.isNotEmpty;
      emit(Unauthenticated(redirectToAccountSelection: otherAccountsExist));
      return;
    }

    try {
      final globalSettings = _store.state.globalSettings;
      final localUserData = _store.state.localUserData[restoreSessionUserId]!;

      if (localUserData.isBiometricAuthenticationEnabled) {
        final authenticationMessage = (await S.delegate.load(
          Locale(globalSettings.preferredLocaleSubtag),
        )).verifyYourIdentity;
        final localAuthSuccess = await _localAuthService.authenticateLocalUser(
          authenticationMessage,
        );
        if (!localAuthSuccess) {
          emit(VerifyingIdentity(userId: restoreSessionUserId));
          return;
        }
      }

      final decryptedState = await _encryptedLocalStore.read(
        restoreSessionUserId,
      );
      if (decryptedState == null) {
        logger.fe(
          "Credentials not found for ${redactUserId(restoreSessionUserId)}.",
          className: runtimeType.toString(),
          methodName: 'restoreSession',
        );
        final otherAccountsExist = _store.state.localUserData.length > 1;
        emit(Unauthenticated(redirectToAccountSelection: otherAccountsExist));
        return;
      }

      _sessionManager.updateSettings(
        clientCertificate: decryptedState.credentials.clientCertificate,
        additionalHeaders: decryptedState.credentials.additionalHeaders,
        authToken: decryptedState.credentials.token,
        baseUrl: localUserData.serverUrl,
        broadcast: false,
      );

      final isPaperlessServerReachable =
          await _connectivityService.isPaperlessServerReachable(
            localUserData.serverUrl,
            decryptedState.credentials.clientCertificate,
            decryptedState.credentials.additionalHeaders,
          ) ==
          ReachabilityStatus.reachable;

      if (isPaperlessServerReachable) {
      } else {
        emit(ConnectionFailure(serverUrl: localUserData.serverUrl));
        return;
      }

      _store.setLoggedInAppUserId(restoreSessionUserId);
      emit(Authenticated(localUserId: restoreSessionUserId));
      logger.fd(
        "Session restored for ${redactUserId(restoreSessionUserId)}.",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
    } catch (error, stackTrace) {
      logger.fe(
        "Failed to restore session.",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        ConnectionFailure(
          serverUrl:
              _store.state.localUserData[restoreSessionUserId]!.serverUrl,
        ),
      );
    }
  }

  Future<void> logout([bool shouldRemoveAccount = false]) async {
    emit(const LoggingOutState());
    final userId = _store.state.loggedInAppUserId!;

    try {
      await _resetExternalState();
      CachedQuery.instance.deleteCache();
      await _notificationService.cancelUserNotifications(userId);
      await _clearSearchIndex(userId);

      final otherAccountsExist = _store.state.localUserData.keys.length > 1;

      if (shouldRemoveAccount) {
        await removeAccount(userId);
      }

      _store.setLoggedInAppUserId(null);
      emit(Unauthenticated(redirectToAccountSelection: otherAccountsExist));
      logger.fd(
        "User ${redactUserId(userId)} logged out.",
        className: runtimeType.toString(),
        methodName: 'logout',
      );
    } catch (error, stackTrace) {
      logger.fe(
        "Error during logout.",
        className: runtimeType.toString(),
        methodName: 'logout',
        error: error,
        stackTrace: stackTrace,
      );
      // Even on error, ensure user is logged out to avoid stuck state.
      _store.setLoggedInAppUserId(null);
      emit(const Unauthenticated());
    }
  }

  /// Never throws, so index teardown cannot break auth cleanup.
  Future<void> _clearSearchIndex(String userId) async {
    try {
      // Only the logged-in user can be the active index user.
      if (_store.state.loggedInAppUserId == userId) {
        await _searchIndexChannel.setActiveUser(null);
      }
      await clearSearchIndex(_searchIndexChannel, _store, userId);
    } catch (error, stackTrace) {
      logger.fe(
        "Failed to clear search index for ${redactUserId(userId)}.",
        className: runtimeType.toString(),
        methodName: '_clearSearchIndex',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _resetExternalState() async {
    _sessionManager.resetSettings();
    await HydratedBloc.storage.clear();
    CachedQuery.instance.deleteCache(deleteStorage: true);
  }

  ///
  /// Adds the user to the local store and persists necessary data.
  /// Returns the user profile of the added user for convenience.
  ///
  Future<UiSettingsView> _addUser(
    String serverUrl,
    String token,
    ClientCertificate? clientCert,
    List<HeaderEntry>? additionalHeaders,
    SessionManager sessionManager,
  ) async {
    sessionManager.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCert,
      additionalHeaders: additionalHeaders,
      authToken: token,
      broadcast: false,
    );

    final uiSettings = await _getUserProfile();
    final localUserId = _buildLocalUserId(uiSettings, serverUrl);

    if (_store.state.localUserData.containsKey(localUserId)) {
      throw InfoMessageException(code: ErrorCode.userAlreadyExists);
    }

    _store.setUserData(
      localUserId,
      LocalUserData(
        userId: localUserId,
        serverUrl: serverUrl,
        username: uiSettings.user.username,
        firstName: uiSettings.user.firstName,
        lastName: uiSettings.user.lastName,
      ),
    );

    _encryptedLocalStore.write(
      localUserId,
      EncryptedLocalStoreState(
        credentials: UserCredentials(
          token: token,
          clientCertificate: clientCert,
          additionalHeaders: additionalHeaders,
        ),
      ),
    );

    _store.updateGlobalSettings(
      (state) => state.copyWith(
        knownHosts: {
          ..._store.state.globalSettings.knownHosts,
          serverUrl,
        }.toList(),
      ),
    );

    return uiSettings;
  }

  Future<UiSettingsView> _getUserProfile() async {
    final uiSettings = await _usersApi.getUiSettings();
    return uiSettings;
  }

  String _buildLocalUserId(UiSettingsView uiSettings, String serverUrl) {
    return '${uiSettings.user.username}@$serverUrl';
  }
}
