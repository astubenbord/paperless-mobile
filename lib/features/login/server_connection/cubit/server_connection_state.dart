part of 'server_connection_cubit.dart';

sealed class ServerConnectionState {
  const ServerConnectionState();
}

class ServerConnectionInitial extends ServerConnectionState {
  const ServerConnectionInitial();
}

class ServerConnectionCheckingReachability extends ServerConnectionState {
  final String address;
  const ServerConnectionCheckingReachability({required this.address});
}

class ServerConnectionSuccess extends ServerConnectionState {
  final String serverUrl;
  final ClientCertificate? clientCertificate;
  final List<HeaderEntry>? additionalHeaders;
  const ServerConnectionSuccess({
    required this.serverUrl,
    this.clientCertificate,
    this.additionalHeaders,
  });
}

class ServerConnectionUnreachable extends ServerConnectionState {
  final String address;
  final ReachabilityStatus status;

  const ServerConnectionUnreachable({
    required this.address,
    required this.status,
  });
}
