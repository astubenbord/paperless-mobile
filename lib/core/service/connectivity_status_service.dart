import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:paperless_mobile/core/global/os_error_codes.dart';
import 'package:paperless_mobile/core/interceptor/server_reachability_error_interceptor.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';

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

  ConnectivityStatusServiceImpl(this._connectivity);

  @override
  Stream<bool> connectivityChanges() {
    return _connectivity.onConnectivityChanged
        .map(_hasActiveInternetConnection)
        .asBroadcastStream();
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

  bool _hasActiveInternetConnection(ConnectivityResult conn) {
    return conn == ConnectivityResult.mobile ||
        conn == ConnectivityResult.wifi ||
        conn == ConnectivityResult.ethernet;
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
          SessionManager([ServerReachabilityErrorInterceptor()])
            ..updateSettings(clientCertificate: clientCertificate)
            ..client.options.connectTimeout = 5000
            ..client.options.receiveTimeout = 5000;

      final response = await manager.client.get('$serverAddress/api/');
      if (response.statusCode == 200) {
        return ReachabilityStatus.reachable;
      }
      return ReachabilityStatus.notReachable;
    } on DioError catch (error) {
      if (error.type == DioErrorType.other &&
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
