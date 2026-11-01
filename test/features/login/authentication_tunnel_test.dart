import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/store/encrypted_local_store.dart';
import 'package:paperless_mobile/core/store/local_store.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/core/store/slices/local_user_data.dart';
import 'package:paperless_mobile/core/store/slices/user_credentials.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';

class _Api extends Mock implements PaperlessUserApi {}

class _Session extends Mock implements SessionManager {}

class _Connectivity extends Mock implements ConnectivityStatusService {}

class _Auth extends Mock implements LocalAuthenticationService {}

class _Notifications extends Mock implements LocalNotificationService {
  @override
  Future<void> cancelUserNotifications(String userId) async {}
}

class _Store extends Mock implements LocalStore {
  @override
  LocalStoreState get state => LocalStoreState(
    globalSettings: GlobalSettings(preferredLocaleSubtag: 'en'),
    loggedInAppUserId: 'old',
    localUserData: {
      'target': const LocalUserData(
        userId: 'target',
        serverUrl: 'https://target.test',
        username: 'target',
      ),
    },
  );
}

class _Encrypted extends Mock implements EncryptedLocalStore {
  @override
  Future<bool> contains(String userId) async => true;
  @override
  Future<EncryptedLocalStoreState?> read(String userId) async =>
      EncryptedLocalStoreState(credentials: UserCredentials(token: 'token'));
}

class _Tunnel extends Mock implements TunnelManager {
  String? url;
  @override
  Future<void> ensureReachable(String serverUrl) async {
    url = serverUrl;
    throw const TunnelException('vpn_not_authorized');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => logger = Logger());
  test('switch account reports tunnel failure for target URL', () async {
    final tunnel = _Tunnel();
    final cubit = AuthenticationCubit(
      _Api(),
      _Session(),
      _Connectivity(),
      _Auth(),
      _Notifications(),
      _Store(),
      _Encrypted(),
      tunnelManager: tunnel,
    );
    await cubit.switchAccount('target');
    expect(tunnel.url, 'https://target.test');
    expect(
      cubit.state,
      isA<ConnectionFailure>().having(
        (s) => s.tunnelErrorCode,
        'code',
        'vpn_not_authorized',
      ),
    );
    await cubit.close();
  });
  test('add user reports tunnel failure', () async {
    final tunnel = _Tunnel();
    final cubit = AuthenticationCubit(
      _Api(),
      _Session(),
      _Connectivity(),
      _Auth(),
      _Notifications(),
      _Store(),
      _Encrypted(),
      tunnelManager: tunnel,
    );
    await cubit.addUser(serverUrl: 'https://new.test', token: 'token');
    expect(tunnel.url, 'https://new.test');
    expect(
      cubit.state,
      isA<AuthenticationError>().having(
        (s) => s.error,
        'error',
        isA<TunnelException>(),
      ),
    );
    await cubit.close();
  });
  test('restore session reports tunnel failure for target URL', () async {
    final tunnel = _Tunnel();
    final cubit = AuthenticationCubit(
      _Api(),
      _Session(),
      _Connectivity(),
      _Auth(),
      _Notifications(),
      _Store(),
      _Encrypted(),
      tunnelManager: tunnel,
    );
    await cubit.restoreSession('target');
    expect(tunnel.url, 'https://target.test');
    expect(
      cubit.state,
      isA<ConnectionFailure>().having(
        (s) => s.tunnelErrorCode,
        'code',
        'vpn_not_authorized',
      ),
    );
    await cubit.close();
  });
}
