abstract class PaperlessAuthenticationApi {
  Future<String> login({
    required String username,
    required String password,
    required String serverUrl,
  });
}
