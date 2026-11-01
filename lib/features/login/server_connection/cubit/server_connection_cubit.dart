import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_manager.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/features/logging/data/logger.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/reachability_status.dart';
import 'package:paperless_mobile/features/login/server_connection/model/header_entry.dart';

part 'server_connection_state.dart';

class ServerConnectionCubit extends Cubit<ServerConnectionState> {
  final ConnectivityStatusService _connectivityStatusService;
  final TunnelManager? tunnelManager;
  ServerConnectionCubit(this._connectivityStatusService, [this.tunnelManager])
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
      await tunnelManager?.ensureReachable(address);
      final status = await _connectivityStatusService
          .isPaperlessServerReachable(
            address,
            clientCertificate,
            additionalHeaders,
          );
      if (status == ReachabilityStatus.reachable) {
        emit(
          ServerConnectionSuccess(
            serverUrl: address,
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
    } on TunnelException catch (error) {
      emit(ServerConnectionTunnelError(address: address, code: error.code));
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
