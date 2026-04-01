import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';

part 'server_connection_state.dart';

class ServerConnectionCubit extends Cubit<ServerConnectionState> {
  final ConnectivityStatusService _connectivityStatusService;
  ServerConnectionCubit(this._connectivityStatusService)
    : super(const ServerConnectionInitial());

  void reset() {
    emit(const ServerConnectionInitial());
  }

  void checkReachability({
    required String address,
    ClientCertificate? clientCertificate,
    List<HeaderEntry>? additionalHeaders,
  }) async {
    emit(ServerConnectionCheckingReachability(address: address));
    try {
      final status = await _connectivityStatusService
          .isPaperlessServerReachable(
            address,
            clientCertificate,
            additionalHeaders,
          );
      final apiVersion = await _connectivityStatusService
          .getPaperlessServerApiVersion(
            address,
            clientCertificate,
            additionalHeaders,
          );
      if (status == ReachabilityStatus.reachable) {
        emit(
          ServerConnectionSuccess(
            serverUrl: address,
            apiVersion: apiVersion,
            clientCertificate: clientCertificate,
            additionalHeaders: additionalHeaders,
          ),
        );
      } else {
        logger.fw(
          'Server is not reachable',
          className: runtimeType.toString(),
          methodName: 'checkReachability',
          error: {'status': status.toString()},
        );
        emit(ServerConnectionUnreachable(address: address, status: status));
      }
    } catch (error, stackTrace) {
      logger.fe(
        'Error while checking server reachability',
        className: runtimeType.toString(),
        methodName: 'checkReachability',
        error: error,
        stackTrace: stackTrace,
      );
      emit(ServerConnectionInitial());
    }
  }
}
