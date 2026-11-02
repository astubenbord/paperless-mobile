/// IPv4 parsing and routing checks for tunnel diagnostics.
int? parseIpv4(String address) {
  final parts = address.split('.');
  if (parts.length != 4) return null;
  var value = 0;
  for (final part in parts) {
    if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(part)) return null;
    final octet = int.tryParse(part);
    if (octet == null || octet > 255) return null;
    value = (value << 8) | octet;
  }
  return value;
}

bool ipv4InCidr(String address, String cidr) {
  final pieces = cidr.split('/');
  if (pieces.length != 2) return false;
  final ip = parseIpv4(address);
  final network = parseIpv4(pieces[0]);
  final prefix = int.tryParse(pieces[1]);
  if (ip == null ||
      network == null ||
      prefix == null ||
      prefix < 0 ||
      prefix > 32) {
    return false;
  }
  final mask = prefix == 0 ? 0 : (0xffffffff << (32 - prefix)) & 0xffffffff;
  return (ip & mask) == (network & mask);
}

bool isPrivateIpv4(String address) =>
    ipv4InCidr(address, '10.0.0.0/8') ||
    ipv4InCidr(address, '172.16.0.0/12') ||
    ipv4InCidr(address, '192.168.0.0/16');
