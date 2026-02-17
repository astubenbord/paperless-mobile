import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/global/os_error_codes.dart';
import 'package:paperless_mobile/core/interceptor/server_reachability_error_interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/core/model/client_certificate.dart';
import 'package:paperless_mobile/core/model/reachability_status.dart';
import 'package:rxdart/subjects.dart';

abstract class ConnectivityStatusService {
  Future<bool> isConnectedToInternet();
  Future<bool> isServerReachable(String serverAddress);
  Stream<bool> connectivityChanges();
  Future<ReachabilityStatus> isPaperlessServerReachable(
    String serverAddress, [
    ClientCertificate? clientCertificate,
  ]);
}

class ConnectivityStatusServiceImpl implements ConnectivityStatusService {
  final Connectivity _connectivity;
  final BehaviorSubject<bool> _connectivityState$ = BehaviorSubject();

  ConnectivityStatusServiceImpl(this._connectivity) {
    _connectivityState$.addStream(
      _connectivity.onConnectivityChanged
          .map(_hasActiveInternetConnection)
          .asBroadcastStream(),
    );
  }

  @override
  Stream<bool> connectivityChanges() {
    return _connectivityState$.asBroadcastStream();
  }

  @override
  Future<bool> isConnectedToInternet() async {
    return _hasActiveInternetConnection(
        await (Connectivity().checkConnectivity()));
  }

  @override
  Future<bool> isServerReachable(String serverAddress) async {
    try {
      var uri = Uri.parse(serverAddress);
      final result = await InternetAddress.lookup(uri.host);
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  bool _hasActiveInternetConnection(List<ConnectivityResult> conns) {
    bool isActiveInternetConnection(ConnectivityResult conn) {
      switch (conn) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.mobile:
        case ConnectivityResult.vpn:
          return true;
        default:
          return false;
      }
    }

    return conns.any(isActiveInternetConnection);
  }

  @override
  Future<ReachabilityStatus> isPaperlessServerReachable(
    String serverAddress, [
    ClientCertificate? clientCertificate,
  ]) async {
    if (!RegExp(r"^https?://.*").hasMatch(serverAddress)) {
      return ReachabilityStatus.unknown;
    }
    try {
      SessionManager manager =
          SessionManagerImpl([ServerReachabilityErrorInterceptor()])
            ..updateSettings(clientCertificate: clientCertificate)
            ..client.options.connectTimeout = const Duration(seconds: 5)
            ..client.options.receiveTimeout = const Duration(seconds: 5);

      final response = await manager.client.get('$serverAddress/api/');
      if (response.statusCode == 200) {
        return ReachabilityStatus.reachable;
      }
      return ReachabilityStatus.notReachable;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.unknown &&
          error.error is ReachabilityStatus) {
        return error.error as ReachabilityStatus;
      }
    } on TlsException catch (error) {
      final code = error.osError?.errorCode;
      if (code == OsErrorCodes.invalidClientCertConfig.code) {
        // Missing client cert passphrase
        return ReachabilityStatus.invalidClientCertificateConfiguration;
      }
    }
    return ReachabilityStatus.notReachable;
  }
}

class ConnectivityStatusServiceMock implements ConnectivityStatusService {
  final bool isConnected;

  ConnectivityStatusServiceMock(this.isConnected);
  @override
  Stream<bool> connectivityChanges() {
    return Stream.value(isConnected);
  }

  @override
  Future<bool> isConnectedToInternet() async {
    return isConnected;
  }

  @override
  Future<ReachabilityStatus> isPaperlessServerReachable(String serverAddress,
      [ClientCertificate? clientCertificate]) async {
    return isConnected
        ? ReachabilityStatus.reachable
        : ReachabilityStatus.notReachable;
  }

  @override
  Future<bool> isServerReachable(String serverAddress) async {
    return isConnected;
  }
}
