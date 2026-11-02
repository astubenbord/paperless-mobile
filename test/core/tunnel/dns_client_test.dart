import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/dns_client.dart';
import 'package:paperless_mobile/core/tunnel/ipv4_cidr.dart';

void main() {
  test('builds recursive A query and parses compressed answer', () {
    final query = buildDnsQuery('example.com', 0x1234);
    expect(query.sublist(0, 6), [0x12, 0x34, 1, 0, 0, 1]);
    final response = <int>[...query];
    response[2] = 0x81;
    response[3] = 0x80;
    response[7] = 1;
    response.addAll([
      0xc0,
      0x0c,
      0,
      1,
      0,
      1,
      0,
      0,
      0,
      30,
      0,
      4,
      192,
      168,
      1,
      5,
    ]);
    expect(parseDnsResponse(response, 0x1234).addresses, ['192.168.1.5']);
    response[3] = 0x83;
    expect(parseDnsResponse(response, 0x1234).status, DnsStatus.nxdomain);
    expect(
      () => parseDnsResponse(response.sublist(0, 5), 0x1234),
      throwsFormatException,
    );
  });
  test('classifies IPv4 networks', () {
    expect(isPrivateIpv4('192.168.1.5'), isTrue);
    expect(isPrivateIpv4('8.8.8.8'), isFalse);
    expect(ipv4InCidr('192.168.1.5', '192.168.1.0/24'), isTrue);
    expect(ipv4InCidr('192.168.2.5', '192.168.1.0/24'), isFalse);
  });
}
