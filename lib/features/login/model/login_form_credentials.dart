class LoginFormCredentials {
  final String? username;
  final String? password;
  final String? apiKey;
  final String? totpCode;

  LoginFormCredentials({
    this.username,
    this.password,
    this.apiKey,
    this.totpCode,
  });

  LoginFormCredentials copyWith({
    String? username,
    String? password,
    String? apiKey,
    String? totpCode,
  }) {
    return LoginFormCredentials(
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      totpCode: totpCode ?? this.totpCode,
    );
  }

  bool get isApiKeyAuth => apiKey != null && apiKey!.isNotEmpty;
}
