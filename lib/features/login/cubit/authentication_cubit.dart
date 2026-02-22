import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/database/tables/local_user_settings.dart';
import 'package:paperless_mobile/core/database/tables/user_credentials.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/core/logging/logger.dart';
import 'package:paperless_mobile/features/logging/utils/redaction_utils.dart';
import 'package:paperless_mobile/core/model/info_message_exception.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/core/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

part 'authentication_state.dart';

typedef _FutureVoidCallback = Future<void> Function();

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final LocalAuthenticationService _localAuthService;
  final PaperlessApiFactory _apiFactory;
  final SessionManager _sessionManager;
  final ConnectivityStatusService _connectivityService;
  final LocalNotificationService _notificationService;

  AuthenticationCubit(
    this._localAuthService,
    this._apiFactory,
    this._sessionManager,
    this._connectivityService,
    this._notificationService,
  ) : super(const UnauthenticatedState());

  Future<void> login({
    required LoginFormCredentials credentials,
    required String serverUrl,
    ClientCertificate? clientCertificate,
  }) async {
    assert(credentials.username != null && credentials.password != null);
    if (state is AuthenticatingState) {
      // Cancel duplicate login requests
      return;
    }
    emit(const AuthenticatingState(AuthenticatingStage.authenticating));
    final localUserId = "${credentials.username}@$serverUrl";
    final redactedId = redactUserId(localUserId);

    logger.fd(
      "Trying to log in $redactedId...",
      className: runtimeType.toString(),
      methodName: 'login',
    );
    try {
      await _addUser(
        localUserId,
        serverUrl,
        credentials,
        clientCertificate,
        _sessionManager,
        onFetchUserInformation: () async {
          emit(const AuthenticatingState(
              AuthenticatingStage.fetchingUserInformation));
        },
        onPerformLogin: () async {
          emit(const AuthenticatingState(AuthenticatingStage.authenticating));
        },
        onPersistLocalUserData: () async {
          emit(const AuthenticatingState(
              AuthenticatingStage.persistingLocalUserData));
        },
      );
    } on PaperlessApiException catch (_) {
      emit(
        AuthenticationErrorState(
          serverUrl: serverUrl,
          username: credentials.username!,
          password: credentials.password!,
          clientCertificate: clientCertificate,
        ),
      );
      rethrow;
    }

    // Mark logged in user as currently active user.
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    globalSettings.loggedInUserId = localUserId;
    await globalSettings.save();

    emit(AuthenticatedState(localUserId: localUserId));
    logger.fd(
      'User $redactedId successfully logged in.',
      className: runtimeType.toString(),
      methodName: 'login',
    );
  }

  /// Switches to another account if it exists.
  Future<void> switchAccount(String localUserId) async {
    emit(const SwitchingAccountsState());
    await FileService.instance.initialize();

    final redactedId = redactUserId(localUserId);
    logger.fd(
      'Trying to switch to user $redactedId...',
      className: runtimeType.toString(),
      methodName: 'switchAccount',
    );

    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;

    final userAccountBox = Hive.localUserAccountBox;

    if (!userAccountBox.containsKey(localUserId)) {
      logger.fw(
        'User $redactedId not yet registered. '
        'This should never be the case!',
        className: runtimeType.toString(),
        methodName: 'switchAccount',
      );
      return;
    }

    final account = userAccountBox.get(localUserId)!;

    if (account.settings.isBiometricAuthenticationEnabled) {
      final authenticated = await _localAuthService
          .authenticateLocalUser("Authenticate to switch your account.");
      if (!authenticated) {
        logger.fw(
          "User could not be authenticated.",
          className: runtimeType.toString(),
          methodName: 'switchAccount',
        );
        emit(VerifyIdentityState(userId: localUserId));
        return;
      }
    }
    final currentlyLoggedInUser = globalSettings.loggedInUserId;
    if (currentlyLoggedInUser != localUserId) {
      await _notificationService.cancelUserNotifications(localUserId);
    }
    await withEncryptedBox<UserCredentials, void>(
        HiveBoxes.localUserCredentials, (credentialsBox) async {
      if (!credentialsBox.containsKey(localUserId)) {
        logger.fw(
          "Invalid authentication for $redactedId.",
          className: runtimeType.toString(),
          methodName: 'switchAccount',
        );
        return;
      }
      final credentials = credentialsBox.get(localUserId);
      await _resetExternalState();

      _sessionManager.updateSettings(
        authToken: credentials!.token,
        clientCertificate: credentials.clientCertificate,
        baseUrl: account.serverUrl,
      );

      globalSettings.loggedInUserId = localUserId;
      await globalSettings.save();

      final apiVersion = await _getApiVersion(_sessionManager.client);

      await _updateRemoteUser(
        _sessionManager,
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount)
            .get(localUserId)!,
        apiVersion,
      );

      emit(AuthenticatedState(localUserId: localUserId));
    });
  }

  Future<String> addAccount({
    required LoginFormCredentials credentials,
    required String serverUrl,
    ClientCertificate? clientCertificate,
    required bool enableBiometricAuthentication,
    required String locale,
  }) async {
    assert(credentials.password != null && credentials.username != null);
    final localUserId = "${credentials.username}@$serverUrl";
    final redactedId = redactUserId(localUserId);
    logger.fd(
      "Adding account $redactedId...",
      className: runtimeType.toString(),
      methodName: 'switchAccount',
    );

    final SessionManager sessionManager = SessionManagerImpl([
      LanguageHeaderInterceptor(() => locale),
    ]);
    await _addUser(
      localUserId,
      serverUrl,
      credentials,
      clientCertificate,
      sessionManager,
    );

    return localUserId;
  }

  Future<void> removeAccount(String userId) async {
    final redactedId = redactUserId(userId);
    logger.fd(
      "Trying to remove account $redactedId...",
      className: runtimeType.toString(),
      methodName: 'removeAccount',
    );
    final userAccountBox = Hive.localUserAccountBox;
    final userAppStateBox = Hive.localUserAppStateBox;

    await FileService.instance.clearUserData(userId: userId);
    await userAccountBox.delete(userId);
    await userAppStateBox.delete(userId);
    await withEncryptedBox<UserCredentials, void>(
        HiveBoxes.localUserCredentials, (box) async {
      await box.delete(userId);
    });
  }

  ///
  /// Restores the previous session if exists.
  ///
  Future<void> restoreSession([String? userId]) async {
    emit(const RestoringSessionState());
    logger.fd(
      "Trying to restore previous session...",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    final restoreSessionForUser = userId ?? globalSettings.loggedInUserId;
    // final localUserId = globalSettings.loggedInUserId;
    if (restoreSessionForUser == null) {
      logger.fd(
        "There is nothing to restore.",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
      final otherAccountsExist = Hive.localUserAccountBox.isNotEmpty;
      // If there is nothing to restore, we can quit here.
      emit(
        UnauthenticatedState(redirectToAccountSelection: otherAccountsExist),
      );
      return;
    }
    final localUserAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    final localUserAccount = localUserAccountBox.get(restoreSessionForUser)!;
    if (localUserAccount.settings.isBiometricAuthenticationEnabled) {
      logger.fd(
        "Verifying user identity...",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
      final authenticationMesage =
          (await S.delegate.load(Locale(globalSettings.preferredLocaleSubtag)))
              .verifyYourIdentity;
      final localAuthSuccess =
          await _localAuthService.authenticateLocalUser(authenticationMesage);
      if (!localAuthSuccess) {
        logger.fw(
          "Identity could not be verified.",
          className: runtimeType.toString(),
          methodName: 'restoreSession',
        );
        emit(VerifyIdentityState(userId: restoreSessionForUser));
        return;
      }
      logger.fd(
        "Identity successfully verified.",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
    }
    logger.fd(
      "Reading encrypted credentials...",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );
    final authentication =
        await withEncryptedBox<UserCredentials, UserCredentials>(
            HiveBoxes.localUserCredentials, (box) {
      return box.get(restoreSessionForUser);
    });

    if (authentication == null) {
      logger.fe(
        "Credentials could not be read!",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
      throw Exception(
        "User should be authenticated but no authentication information was found.",
      );
    }
    logger.fd(
      "Credentials successfully retrieved.",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );

    logger.fd(
      "Updating security context...",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );

    _sessionManager.updateSettings(
      clientCertificate: authentication.clientCertificate,
      authToken: authentication.token,
      baseUrl: localUserAccount.serverUrl,
    );
    logger.fd(
      "Security context successfully updated.",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );
    final isPaperlessServerReachable =
        await _connectivityService.isPaperlessServerReachable(
              localUserAccount.serverUrl,
              authentication.clientCertificate,
            ) ==
            ReachabilityStatus.reachable;
    logger.fd(
      "Trying to update remote paperless user...",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );
    if (isPaperlessServerReachable) {
      final apiVersion = await _getApiVersion(_sessionManager.client);
      await _updateRemoteUser(
        _sessionManager,
        localUserAccount,
        apiVersion,
      );
      logger.fd(
        "Successfully updated remote paperless user.",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
    } else {
      logger.fw(
        "Could not update remote paperless user - "
        "Server could not be reached. The app might behave unexpected!",
        className: runtimeType.toString(),
        methodName: 'restoreSession',
      );
    }
    globalSettings.loggedInUserId = restoreSessionForUser;
    await globalSettings.save();
    emit(AuthenticatedState(localUserId: restoreSessionForUser));

    logger.fd(
      "Previous session successfully restored.",
      className: runtimeType.toString(),
      methodName: 'restoreSession',
    );
  }

  Future<void> logout([bool shouldRemoveAccount = false]) async {
    emit(const LoggingOutState());
    final globalSettings = Hive.globalSettingsBox.getValue()!;
    final userId = globalSettings.loggedInUserId!;
    final redactedId = redactUserId(userId);

    logger.fd(
      "Logging out $redactedId...",
      className: runtimeType.toString(),
      methodName: 'logout',
    );

    await _resetExternalState();
    await _notificationService.cancelUserNotifications(userId);

    final otherAccountsExist = Hive.localUserAccountBox.length > 1;
    emit(UnauthenticatedState(redirectToAccountSelection: otherAccountsExist));
    if (shouldRemoveAccount) {
      await removeAccount(userId);
    }
    globalSettings.loggedInUserId = null;
    await globalSettings.save();

    logger.fd(
      "User successfully logged out.",
      className: runtimeType.toString(),
      methodName: 'logout',
    );
  }

  Future<void> _resetExternalState() async {
    logger.fd(
      "Resetting security context...",
      className: runtimeType.toString(),
      methodName: '_resetExternalState',
    );
    _sessionManager.resetSettings();
    logger.fd(
      "Security context reset.",
      className: runtimeType.toString(),
      methodName: '_resetExternalState',
    );
    logger.fd(
      "Clearing local state...",
      className: runtimeType.toString(),
      methodName: '_resetExternalState',
    );
    await HydratedBloc.storage.clear();
    logger.fd(
      "Local state cleard.",
      className: runtimeType.toString(),
      methodName: '_resetExternalState',
    );
  }

  Future<int> _addUser(
    String localUserId,
    String serverUrl,
    LoginFormCredentials credentials,
    ClientCertificate? clientCert,
    SessionManager sessionManager, {
    _FutureVoidCallback? onPerformLogin,
    _FutureVoidCallback? onPersistLocalUserData,
    _FutureVoidCallback? onFetchUserInformation,
  }) async {
    assert(credentials.username != null && credentials.password != null);
    final redactedId = redactUserId(localUserId);

    logger.fd(
      "Adding new user $redactedId..",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );

    sessionManager.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCert,
    );

    final authApi = _apiFactory.createAuthenticationApi(sessionManager.client);

    await onPerformLogin?.call();
    logger.fd(
      "Fetching bearer token from the server...",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );
    final token = await authApi.login(
      username: credentials.username!,
      password: credentials.password!,
    );

    logger.fd(
      "Bearer token successfully retrieved.",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );

    sessionManager.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCert,
      authToken: token,
    );
    final userAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    final userStateBox =
        Hive.box<LocalUserAppState>(HiveBoxes.localUserAppState);

    if (userAccountBox.containsKey(localUserId)) {
      logger.fw(
        "The user $redactedId already exists.",
        className: runtimeType.toString(),
        methodName: '_addUser',
      );
      throw InfoMessageException(code: ErrorCode.userAlreadyExists);
    }
    await onFetchUserInformation?.call();
    final apiVersion = await _getApiVersion(sessionManager.client);
    logger.fd(
      "Trying to fetch remote paperless user for $redactedId.",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );

    late UserModel serverUser;
    try {
      serverUser = await _apiFactory
          .createUserApi(
            sessionManager.client,
            apiVersion: apiVersion,
          )
          .findCurrentUser();
    } on DioException catch (error, stackTrace) {
      logger.fe(
        "An error occurred while fetching the remote paperless user.",
        className: runtimeType.toString(),
        methodName: '_addUser',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
    logger.fd(
      "Remote paperless user successfully fetched.",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );

    logger.fd(
      "Persisting user account information...",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );

    await onPersistLocalUserData?.call();
    // Create user account
    await userAccountBox.put(
      localUserId,
      LocalUserAccount(
        id: localUserId,
        settings: LocalUserSettings(),
        serverUrl: serverUrl,
        paperlessUser: serverUser,
        apiVersion: apiVersion,
      ),
    );
    logger.fd(
      "User account information successfully persisted.",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );
    logger.fd(
      "Persisting user app state...",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );
    // Create user state
    await userStateBox.put(
      localUserId,
      LocalUserAppState(userId: localUserId),
    );
    logger.fd(
      "User state successfully persisted.",
      className: runtimeType.toString(),
      methodName: '_addUser',
    );
    // Save credentials in encrypted box
    await withEncryptedBox(HiveBoxes.localUserCredentials, (box) async {
      logger.fd(
        "Saving user credentials inside encrypted storage...",
        className: runtimeType.toString(),
        methodName: '_addUser',
      );

      await box.put(
        localUserId,
        UserCredentials(
          token: token,
          clientCertificate: clientCert,
        ),
      );

      logger.fd(
        "User credentials successfully saved.",
        className: runtimeType.toString(),
        methodName: '_addUser',
      );
    });

    final hostsBox = Hive.box<String>(HiveBoxes.hosts);
    if (!hostsBox.values.contains(serverUrl)) {
      await hostsBox.add(serverUrl);
      logger.fd(
        "Added new url to list of hosts.",
        className: runtimeType.toString(),
        methodName: '_addUser',
      );
    }

    return serverUser.id;
  }

  Future<int> _getApiVersion(
    Dio dio, {
    Duration? timeout,
    int defaultValue = 2,
  }) async {
    logger.fd(
      "Trying to fetch API version...",
      className: runtimeType.toString(),
      methodName: '_getApiVersion',
    );
    try {
      final response = await dio.get(
        "/api/",
        options: Options(sendTimeout: timeout),
      );
      int apiVersion =
          int.parse(response.headers.value('x-api-version') ?? "3");
      if (apiVersion > latestSupportedApiVersion) {
        logger.fw(
          "The server is running a newer API version ($apiVersion) than the app supports (v$latestSupportedApiVersion), falling back to latest supported version (v$latestSupportedApiVersion). "
          "Warning: This might lead to unexpected behavior!",
          className: runtimeType.toString(),
          methodName: '_getApiVersion',
        );
        apiVersion = latestSupportedApiVersion;
      }
      logger.fd(
        "Successfully retrieved API version ($apiVersion).",
        className: runtimeType.toString(),
        methodName: '_getApiVersion',
      );

      return apiVersion;
    } on DioException catch (_) {
      logger.fw(
        "Could not retrieve API version, using default ($defaultValue).",
        className: runtimeType.toString(),
        methodName: '_getApiVersion',
      );
      return defaultValue;
    }
  }

  /// Fetches possibly updated (permissions, name, updated server version and thus new user model, ...) remote user data.
  Future<void> _updateRemoteUser(
    SessionManager sessionManager,
    LocalUserAccount localUserAccount,
    int apiVersion,
  ) async {
    logger.fd(
      "Trying to update remote user object...",
      className: runtimeType.toString(),
      methodName: '_updateRemoteUser',
    );
    final updatedPaperlessUser = await _apiFactory
        .createUserApi(sessionManager.client, apiVersion: apiVersion)
        .findCurrentUser();

    localUserAccount.paperlessUser = updatedPaperlessUser;
    await localUserAccount.save();
    logger.fd(
      "Successfully updated remote user object.",
      className: runtimeType.toString(),
      methodName: '_updateRemoteUser',
    );
  }
}
