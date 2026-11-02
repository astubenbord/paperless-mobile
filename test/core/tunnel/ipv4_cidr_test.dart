import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/tunnel/ipv4_cidr.dart';

void main() {
  test('checks IPv4 prefixes including boundary lengths', () {
    expect(ipv4InCidr('192.168.2.6', '192.168.2.0/24'), isTrue);
    expect(ipv4InCidr('192.168.3.6', '192.168.2.0/24'), isFalse);
    expect(ipv4InCidr('8.8.8.8', '0.0.0.0/0'), isTrue);
    expect(ipv4InCidr('192.168.2.6', '192.168.2.6/32'), isTrue);
    expect(ipv4InCidr('192.168.2.7', '192.168.2.6/32'), isFalse);
    expect(ipv4InCidr('192.168.2.256', '0.0.0.0/0'), isFalse);
    expect(ipv4InCidr('::1', '0.0.0.0/0'), isFalse);
    expect(ipv4InCidr('1.2.3.4', '0.0.0.0/33'), isFalse);
  });
  test('recognizes RFC1918 ranges', () {
    expect(isPrivateIpv4('10.1.2.3'), isTrue);
    expect(isPrivateIpv4('172.31.255.255'), isTrue);
    expect(isPrivateIpv4('172.32.0.1'), isFalse);
    expect(isPrivateIpv4('192.168.2.6'), isTrue);
    expect(isPrivateIpv4('8.8.8.8'), isFalse);
  });
}
