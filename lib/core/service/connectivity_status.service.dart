import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class ConnectivityStatusService {
  Future<bool> isConnectedToInternet();
  Future<bool> isServerReachable(String serverAddress);
  Stream<bool> connectivityChanges();
}

@Injectable(as: ConnectivityStatusService)
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
      final result = await InternetAddress.lookup(
          serverAddress.replaceAll(RegExp(r"https?://"), ""));
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
