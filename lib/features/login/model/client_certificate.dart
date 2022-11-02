import 'dart:convert';
import 'dart:typed_data';

import 'package:paperless_mobile/core/type/json.dart';

class ClientCertificate {
  static const bytesKey = 'bytes';
  static const passphraseKey = 'passphrase';

  final Uint8List bytes;
  final String? passphrase;

  ClientCertificate({required this.bytes, this.passphrase});

  static ClientCertificate? nullable(Uint8List? bytes, {String? passphrase}) {
    if (bytes != null) {
      return ClientCertificate(bytes: bytes, passphrase: passphrase);
    }
    return null;
  }

  JSON toJson() {
    return {
      bytesKey: base64Encode(bytes),
      passphraseKey: passphrase,
    };
  }

  ClientCertificate.fromJson(JSON json)
      : bytes = base64Decode(json[bytesKey]),
        passphrase = json[passphraseKey];

  ClientCertificate copyWith({Uint8List? bytes, String? passphrase}) {
    return ClientCertificate(
      bytes: bytes ?? this.bytes,
      passphrase: passphrase ?? this.passphrase,
    );
  }
}
