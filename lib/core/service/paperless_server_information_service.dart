import 'dart:convert';

import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_mobile/core/model/paperless_server_information.dart';
import 'package:paperless_mobile/core/store/local_vault.dart';

@injectable
class PaperlessServerInformationService {
  final BaseClient client;
  final LocalVault localStore;

  PaperlessServerInformationService(
    @Named("timeoutClient") this.client,
    this.localStore,
  );

  Future<PaperlessServerInformation> getInformation() async {
    final response = await client.get(Uri.parse("/api/ui_settings/"));
    final version =
        response.headers[PaperlessServerInformation.versionHeader] ?? 'unknown';
    final apiVersion = int.tryParse(
        response.headers[PaperlessServerInformation.apiVersionHeader] ?? '1');
    final String username =
        jsonDecode(utf8.decode(response.bodyBytes))['username'];
    final String? host =
        response.headers[PaperlessServerInformation.hostHeader] ??
            response.request?.headers[PaperlessServerInformation.hostHeader] ??
            ('${response.request?.url.host}:${response.request?.url.port}');
    return PaperlessServerInformation(
      username: username,
      version: version,
      apiVersion: apiVersion,
      host: host,
    );
  }
}
