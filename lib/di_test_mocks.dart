import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<PaperlessDocumentsApi>(),
  MockSpec<PaperlessLabelsApi>(),
  MockSpec<PaperlessSavedViewsApi>(),
  MockSpec<PaperlessAuthenticationApi>(),
  MockSpec<PaperlessServerStatsApi>(),
  MockSpec<LocalVault>(),
  MockSpec<EncryptedSharedPreferences>(),
  MockSpec<ConnectivityStatusService>(),
  MockSpec<LocalAuthentication>(),
])
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/service/connectivity_status.service.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';
import 'di_test_mocks.mocks.dart';

@module
abstract class DiMocksModule {
  // All fields must be singleton in order to verify behavior in tests.
  @singleton
  @test
  CacheManager get testCacheManager => CacheManager(Config('testKey'));

  @singleton
  @test
  PaperlessDocumentsApi get mockDocumentsApi => MockPaperlessDocumentsApi();

  @singleton
  @test
  PaperlessLabelsApi get mockLabelsApi => MockPaperlessLabelsApi();

  @singleton
  @test
  PaperlessSavedViewsApi get mockSavedViewsApi => MockPaperlessSavedViewsApi();

  @singleton
  @test
  PaperlessAuthenticationApi get mockAuthenticationApi =>
      MockPaperlessAuthenticationApi();

  @singleton
  @test
  PaperlessServerStatsApi get mockServerStatsApi =>
      MockPaperlessServerStatsApi();

  @singleton
  @test
  LocalVault get mockLocalVault => MockLocalVault();

  @singleton
  @test
  EncryptedSharedPreferences get mockSharedPreferences =>
      MockEncryptedSharedPreferences();

  @singleton
  @test
  ConnectivityStatusService get mockConnectivityStatusService =>
      MockConnectivityStatusService();

  @singleton
  @test
  LocalAuthentication get localAuthentication => MockLocalAuthentication();
}
