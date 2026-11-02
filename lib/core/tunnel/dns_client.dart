import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'ipv4_cidr.dart';

enum DnsStatus { success, nxdomain, servfail }

class DnsResult {
  const DnsResult(this.status, this.addresses);
  final DnsStatus status;
  final List<String> addresses;
}

Uint8List buildDnsQuery(String name, int id) {
  final bytes = <int>[id >> 8, id & 255, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0];
  for (final label in name.replaceFirst(RegExp(r'\.$'), '').split('.')) {
    final data = label.codeUnits;
    if (data.isEmpty || data.length > 63 || data.any((v) => v > 127))
      throw FormatException('Invalid DNS name');
    bytes.add(data.length);
    bytes.addAll(data);
  }
  bytes.addAll([0, 0, 1, 0, 1]);
  if (bytes.length > 512) throw FormatException('DNS name too long');
  return Uint8List.fromList(bytes);
}

DnsResult parseDnsResponse(List<int> data, int id) {
  int u16(int p) {
    if (p + 2 > data.length) throw FormatException('Truncated DNS packet');
    return (data[p] << 8) | data[p + 1];
  }

  if (data.length < 12 ||
      u16(0) != id ||
      (data[2] & 0x80) == 0 ||
      (data[2] & 2) != 0)
    throw FormatException('Invalid DNS response');
  final rcode = data[3] & 15;
  if (rcode == 3) return const DnsResult(DnsStatus.nxdomain, []);
  if (rcode == 2) return const DnsResult(DnsStatus.servfail, []);
  if (rcode != 0) throw FormatException('DNS error $rcode');
  int skipName(int start) {
    var p = start;
    var end = -1;
    final seen = <int>{};
    while (true) {
      if (p >= data.length || !seen.add(p))
        throw FormatException('Invalid DNS name');
      final n = data[p++];
      if (n == 0) return end < 0 ? p : end;
      if ((n & 0xc0) == 0xc0) {
        if (p >= data.length) throw FormatException('Truncated DNS pointer');
        final target = ((n & 0x3f) << 8) | data[p++];
        if (end < 0) end = p;
        p = target;
      } else {
        if ((n & 0xc0) != 0 || p + n > data.length)
          throw FormatException('Invalid DNS label');
        p += n;
      }
    }
  }

  var pos = 12;
  for (var i = 0; i < u16(4); i++) {
    pos = skipName(pos);
    u16(pos);
    u16(pos + 2);
    pos += 4;
  }
  final addresses = <String>[];
  for (var i = 0; i < u16(6); i++) {
    pos = skipName(pos);
    final type = u16(pos);
    final cls = u16(pos + 2);
    final length = u16(pos + 8);
    pos += 10;
    if (pos + length > data.length)
      throw FormatException('Truncated DNS record');
    if (type == 1 && cls == 1 && length == 4)
      addresses.add(data.sublist(pos, pos + 4).join('.'));
    pos += length;
  }
  return DnsResult(DnsStatus.success, addresses);
}

typedef DnsExchange =
    Future<List<int>> Function(String server, Uint8List query);

class DnsClient {
  DnsClient({DnsExchange? exchange, Random? random})
    : _exchange = exchange ?? _udp,
      _random = random ?? Random.secure();
  final DnsExchange _exchange;
  final Random _random;
  Future<DnsResult> lookup(String name, String server) async {
    if (parseIpv4(server) == null)
      throw FormatException('DNS server must be IPv4');
    final id = _random.nextInt(65536);
    final response = await _exchange(
      server,
      buildDnsQuery(name, id),
    ).timeout(const Duration(seconds: 3));
    return parseDnsResponse(response, id);
  }

  static Future<List<int>> _udp(String server, Uint8List query) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      socket.send(query, InternetAddress(server), 53);
      await for (final event in socket.timeout(const Duration(seconds: 3))) {
        if (event == RawSocketEvent.read) {
          final packet = socket.receive();
          if (packet != null &&
              packet.address.address == server &&
              packet.port == 53)
            return packet.data;
        }
      }
      throw SocketException('DNS socket closed');
    } finally {
      socket.close();
    }
  }
}
