abstract class PaperlessAuthenticationApi {
  Future<String> login({
    required String username,
    required String password,
  });

  Future<String> validateApiKey({
    required String apiKey,
  });
}
