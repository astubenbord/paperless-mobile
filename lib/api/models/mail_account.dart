import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_mobile/api/models/account_type_enum.dart';
import 'package:paperless_mobile/api/models/imap_security_enum.dart';

part 'mail_account.freezed.dart';
part 'mail_account.g.dart';

@Freezed(toJson: false, fromJson: true)
abstract class MailAccount with _$MailAccount {
  factory MailAccount({
    required int id,
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
    required bool userCanChange,
    // minimum: 0.0
    // maximum: 2.147483647E9
    AccountTypeEnum? accountType,

    /// The expiration date of the refresh token.
    DateTime? expiration,
  }) = _MailAccount;

  factory MailAccount.fromJson(Map<String, dynamic> json) =>
      _$MailAccountFromJson(json);
}
