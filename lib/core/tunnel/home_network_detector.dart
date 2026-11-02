import 'tunnel_channel.dart';

enum HomeNetworkState { atHome, away, unknown }

enum HomeNetworkReason { noHomeSsids, permissionMissing, locationOff, unknown }

class HomeNetworkResult {
  const HomeNetworkResult(this.state, {this.ssid, this.reason});
  final HomeNetworkState state;
  final String? ssid;
  final HomeNetworkReason? reason;
}

class HomeNetworkDetector {
  HomeNetworkDetector(this.currentSsid);
  final Future<SsidResult> Function() currentSsid;

  Future<HomeNetworkResult> detect(List<String> homeSsids) async {
    if (homeSsids.isEmpty) {
      return const HomeNetworkResult(
        HomeNetworkState.unknown,
        reason: HomeNetworkReason.noHomeSsids,
      );
    }
    try {
      final result = await currentSsid();
      switch (result.status) {
        case SsidStatus.ok:
          if (result.ssid == null || result.ssid!.isEmpty) {
            return const HomeNetworkResult(
              HomeNetworkState.unknown,
              reason: HomeNetworkReason.unknown,
            );
          }
          return HomeNetworkResult(
            homeSsids.contains(result.ssid)
                ? HomeNetworkState.atHome
                : HomeNetworkState.away,
            ssid: result.ssid,
          );
        case SsidStatus.notWifi:
          return const HomeNetworkResult(HomeNetworkState.away);
        case SsidStatus.permissionMissing:
          return const HomeNetworkResult(
            HomeNetworkState.unknown,
            reason: HomeNetworkReason.permissionMissing,
          );
        case SsidStatus.locationOff:
          return const HomeNetworkResult(
            HomeNetworkState.unknown,
            reason: HomeNetworkReason.locationOff,
          );
        case SsidStatus.unknown:
          return const HomeNetworkResult(
            HomeNetworkState.unknown,
            reason: HomeNetworkReason.unknown,
          );
      }
    } catch (_) {
      return const HomeNetworkResult(
        HomeNetworkState.unknown,
        reason: HomeNetworkReason.unknown,
      );
    }
  }
}
