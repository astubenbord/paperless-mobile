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

  /// Android only: Alias of a private key + certificate chain stored in the
  /// user's system credential store ("VPN and apps" / Android KeyChain).
  ///
  /// When set, the app should use the Android KeyChain APIs (via a platform
  /// channel) to perform mutual TLS, instead of parsing a PKCS#12 file.
  @HiveField(3)
  final String? androidKeyAlias;

  ClientCertificate({
    required this.bytes,
    required this.filename,
    this.passphrase,
    this.androidKeyAlias,
  });

  ClientCertificate copyWith({
    Uint8List? bytes,
    String? filename,
    String? passphrase,
    String? androidKeyAlias,
  }) {
    return ClientCertificate(
      bytes: bytes ?? this.bytes,
      filename: filename ?? this.filename,
      passphrase: passphrase ?? this.passphrase,
      androidKeyAlias: androidKeyAlias ?? this.androidKeyAlias,
    );
  }
}
