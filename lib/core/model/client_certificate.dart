import 'dart:typed_data';

import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';

part 'client_certificate.g.dart';

@HiveType(typeId: HiveTypeIds.clientCertificate)
class ClientCertificate {
  @HiveField(0)
  final Uint8List bytes;
  @HiveField(2, defaultValue: "cert.pfx")
  final String filename;
  @HiveField(1)
  final String? passphrase;

  ClientCertificate({
    required this.bytes,
    required this.filename,
    this.passphrase,
  });

  ClientCertificate copyWith({
    Uint8List? bytes,
    String? filename,
    String? passphrase,
  }) {
    return ClientCertificate(
      bytes: bytes ?? this.bytes,
      filename: filename ?? this.filename,
      passphrase: passphrase ?? this.passphrase,
    );
  }
}
