import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/account_type_enum.dart';
import 'package:paperless_mobile/api/models/correspondent_request_set_permissions.dart';
import 'package:paperless_mobile/api/models/imap_security_enum.dart';
import 'package:paperless_mobile/api/utils/patched_value.dart';

part 'patched_mail_account_request.g.dart';

@JsonSerializable(
  createFactory: false,
  createToJson: true,
  includeIfNull: false,
)
class PatchedMailAccountRequest {
  final PatchedValue<String?>? name;
  final PatchedValue<String?>? imapServer;

  // minimum: -2147483648
  // maximum: 2147483647
  final PatchedValue<int?>? imapPort;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<ImapSecurityEnum?>? imapSecurity;
  final PatchedValue<String?>? username;
  final PatchedValue<String?>? password;

  /// The character set to use when communicating with the mail server, such as 'UTF-8' or 'US-ASCII'.
  final PatchedValue<String?>? characterSet;
  final PatchedValue<bool?>? isToken;
  final PatchedValue<int?>? owner;
  final PatchedValue<CorrespondentRequestSetPermissions?>? setPermissions;

  // minimum: 0.0
  // maximum: 2.147483647E9
  final PatchedValue<AccountTypeEnum?>? accountType;

  /// The expiration date of the refresh token.
  final PatchedValue<DateTime?>? expiration;

  PatchedMailAccountRequest({
    this.name,
    this.imapServer,
    this.imapPort,
    this.imapSecurity,
    this.username,
    this.password,
    this.characterSet,
    this.isToken,
    this.owner,
    this.setPermissions,
    this.accountType,
    this.expiration,
  });

  Map<String, dynamic> toJson() =>
      processPatchedValueJson(_$PatchedMailAccountRequestToJson(this));
}
