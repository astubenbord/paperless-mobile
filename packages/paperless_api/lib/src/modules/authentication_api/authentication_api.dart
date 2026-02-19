abstract class PaperlessAuthenticationApi {
  Future<String> login({
    required String username,
    required String password,
    String? totpCode,
  });

  Future<bool> validateApiKey(String apiKey);
}
