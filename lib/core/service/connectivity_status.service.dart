import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class ConnectivityStatusService {
  Future<bool> isConnectedToInternet();
  Future<bool> isServerReachable(String serverAddress);
  Stream<bool> connectivityChanges();
}

@Injectable(as: ConnectivityStatusService, env: ['prod', 'dev'])
class ConnectivityStatusServiceImpl implements ConnectivityStatusService {
  final Connectivity connectivity;

  ConnectivityStatusServiceImpl(this.connectivity);

  @override
  Stream<bool> connectivityChanges() {
    return connectivity.onConnectivityChanged
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
}
