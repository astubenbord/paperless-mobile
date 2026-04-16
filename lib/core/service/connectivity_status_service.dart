import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/global/os_error_codes.dart';
import 'package:paperless_mobile/core/interceptor/server_reachability_error_interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/security/session_manager_impl.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';
import 'package:rxdart/subjects.dart';

abstract class ConnectivityStatusService {
  Future<bool> isConnectedToInternet();
  Future<bool> isServerReachable(String serverAddress);
  Stream<bool> connectivityChanges();
  Future<ReachabilityStatus> isPaperlessServerReachable(
    String serverAddress, [
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  ]);
  Future<int> getPaperlessServerApiVersion(
    String serverAddress, [
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
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
      await (Connectivity().checkConnectivity()),
    );
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
    List<HeaderEntry>? additionalHeaders,
  ]) async {
    if (!RegExp(r"^https?://.*").hasMatch(serverAddress)) {
      return ReachabilityStatus.unknown;
    }
    try {
      SessionManager manager =
          SessionManagerImpl([ServerReachabilityErrorInterceptor()])
            ..updateSettings(
              baseUrl: serverAddress,
              clientCertificate: clientCertificate,
              additionalHeaders: additionalHeaders,
            );

      final response = await manager.client.head(
        '/api/schema/',
        options: Options(
          receiveTimeout: 5.seconds,
          sendTimeout: 5.seconds,
          followRedirects: true,
        ),
      );
      if (response.statusCode == 200) {
        return ReachabilityStatus.reachable;
      }
      logger.fw(
        'Unexpected response status code: ${response.statusCode}',
        className: runtimeType.toString(),
        methodName: 'isPaperlessServerReachable',
        error: {
          'statusCode': response.statusCode,
          'data': response.data.toString(),
        },
      );
      return ReachabilityStatus.notReachable;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.unknown &&
          error.error is ReachabilityStatus) {
        logger.fw(
          'Could not reach server: ${error.error}',
          className: runtimeType.toString(),
          methodName: 'isPaperlessServerReachable',
          error: {
            'statusCode': error.response?.statusCode,
            'data': error.response?.data.toString(),
          },
        );
        return error.error as ReachabilityStatus;
      }
    } on TlsException catch (error) {
      final code = error.osError?.errorCode;
      if (code == OsErrorCodes.invalidClientCertConfig.code) {
        // Missing client cert passphrase
        return ReachabilityStatus.invalidClientCertificateConfiguration;
      }
      logger.fw(
        'Could not reach server due to an SSL/TLS issue: ${error.message}',
        className: runtimeType.toString(),
        methodName: 'isPaperlessServerReachable',
      );
    }
    return ReachabilityStatus.notReachable;
  }

  @override
  Future<int> getPaperlessServerApiVersion(
    String serverAddress, [
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  ]) async {
    SessionManager manager = SessionManagerImpl()
      ..updateSettings(
        baseUrl: serverAddress,
        clientCertificate: clientCertificate,
        additionalHeaders: additionalHeaders,
      );

    int apiVersion = await manager.getApiVersion();

    if (apiVersion > latestSupportedApiVersion) {
      logger.fw(
        'Server API version $apiVersion is newer than the latest supported version $latestSupportedApiVersion. Defaulting to latest supported version.',
        className: runtimeType.toString(),
        methodName: 'getPaperlessServerApiVersion',
      );
      apiVersion = latestSupportedApiVersion;
    }
    return apiVersion;
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
  Future<ReachabilityStatus> isPaperlessServerReachable(
    String serverAddress, [
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  ]) async {
    return isConnected
        ? ReachabilityStatus.reachable
        : ReachabilityStatus.notReachable;
  }

  @override
  Future<bool> isServerReachable(String serverAddress) async {
    return isConnected;
  }

  @override
  Future<int> getPaperlessServerApiVersion(
    String serverAddress, [
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  ]) {
    return Future.value(9);
  }
}
