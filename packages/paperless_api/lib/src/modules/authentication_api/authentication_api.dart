abstract class PaperlessAuthenticationApi {
  Future<String> login({
    required String username,
    required String password,
    String? totpCode,
  });

  Future<String> validateApiKey({
    required String apiKey,
  });
}
