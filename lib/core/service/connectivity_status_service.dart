import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
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
    late SecurityContext context = SecurityContext();
    try {
      if (clientCertificate != null) {
        context
          ..usePrivateKeyBytes(
            clientCertificate.bytes,
            password: clientCertificate.passphrase,
          )
          ..useCertificateChainBytes(
            clientCertificate.bytes,
            password: clientCertificate.passphrase,
          )
          ..setTrustedCertificatesBytes(
            clientCertificate.bytes,
            password: clientCertificate.passphrase,
          );
      }

      final adapter = DefaultHttpClientAdapter()
        ..onHttpClientCreate = (client) => HttpClient(context: context)
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
      final Dio dio = Dio()..httpClientAdapter = adapter;

      final response = await dio.get('$serverAddress/api/');
      if (response.statusCode == 200) {
        return ReachabilityStatus.reachable;
      }
      return ReachabilityStatus.notReachable;
    } on DioError catch (error) {
      if (error.error is String) {
        if (error.response?.data is String) {
          if ((error.response!.data as String)
              .contains("No required SSL certificate was sent")) {
            return ReachabilityStatus.missingClientCertificate;
          }
        }
      }
      return ReachabilityStatus.notReachable;
    } on TlsException catch (error) {
      if (error.osError?.errorCode == 318767212) {
        //INCORRECT_PASSWORD for certificate
        return ReachabilityStatus.invalidClientCertificateConfiguration;
      }
      return ReachabilityStatus.notReachable;
    }
  }
}
