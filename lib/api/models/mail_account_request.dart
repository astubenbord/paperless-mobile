import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/account_type_enum.dart';
import 'package:paperless_mobile/api/models/correspondent_request_set_permissions.dart';
import 'package:paperless_mobile/api/models/imap_security_enum.dart';

part 'mail_account_request.freezed.dart';
part 'mail_account_request.g.dart';

@Freezed(toJson: true, fromJson: false)
abstract class MailAccountRequest with _$MailAccountRequest {
  factory MailAccountRequest({
    required String name,
    required String imapServer,

    // minimum: -2147483648
    // maximum: 2147483647
    int? imapPort,
    // minimum: 0.0
    // maximum: 2.147483647E9
    ImapSecurityEnum? imapSecurity,
    required String username,
    required String password,

    /// The character set to use when communicating with the mail server, such as 'UTF-8' or 'US-ASCII'.
    String? characterSet,
    bool? isToken,
    int? owner,
    CorrespondentRequestSetPermissions? setPermissions,
    // minimum: 0.0
    // maximum: 2.147483647E9
    AccountTypeEnum? accountType,

    /// The expiration date of the refresh token.
    DateTime? expiration,
  }) = _MailAccountRequest;
}
