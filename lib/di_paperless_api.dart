import 'dart:io';

import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:paperless_api/paperless_api.dart';

@module
abstract class PaperlessApiModule {
  @prod
  @Order(-1)
  @injectable
  PaperlessAuthenticationApi authenticationModule(BaseClient client) =>
      PaperlessAuthenticationApiImpl(client);

  @prod
  @Order(-1)
  @injectable
  PaperlessLabelsApi labelsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
  ) =>
      PaperlessLabelApiImpl(timeoutClient);

  @prod
  @Order(-1)
  @injectable
  PaperlessDocumentsApi documentsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
    HttpClient httpClient,
  ) =>
      PaperlessDocumentsApiImpl(timeoutClient, httpClient);

  @prod
  @Order(-1)
  @injectable
  PaperlessSavedViewsApi savedViewsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
  ) =>
      PaperlessSavedViewsApiImpl(timeoutClient);

  @prod
  @Order(-1)
  @injectable
  PaperlessServerStatsApi serverStatsModule(
    @Named('timeoutClient') BaseClient timeoutClient,
  ) =>
      PaperlessServerStatsApiImpl(timeoutClient);
}
