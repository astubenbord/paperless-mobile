import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/home_network_detector.dart';
import 'package:paperless_mobile/core/tunnel/tunnel_channel.dart';

void main() {
  test('classifies SSID and platform statuses', () async {
    Future<HomeNetworkResult> detect(
      SsidResult value, [
      List<String> names = const ['Home'],
    ]) => HomeNetworkDetector(() async => value).detect(names);
    expect(
      (await detect(const SsidResult('Home', SsidStatus.ok))).state,
      HomeNetworkState.atHome,
    );
    expect(
      (await detect(const SsidResult('home', SsidStatus.ok))).state,
      HomeNetworkState.away,
    );
    expect(
      (await detect(const SsidResult(null, SsidStatus.notWifi))).state,
      HomeNetworkState.away,
    );
    expect(
      (await detect(
        const SsidResult(null, SsidStatus.permissionMissing),
      )).reason,
      HomeNetworkReason.permissionMissing,
    );
    expect(
      (await detect(const SsidResult(null, SsidStatus.locationOff))).reason,
      HomeNetworkReason.locationOff,
    );
    expect(
      (await detect(const SsidResult('Home', SsidStatus.ok), [])).reason,
      HomeNetworkReason.noHomeSsids,
    );
  });
}
