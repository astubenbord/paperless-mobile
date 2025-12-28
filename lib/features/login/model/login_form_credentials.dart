class LoginFormCredentials {
  final String? username;
  final String? password;
  final String? apiKey;

  LoginFormCredentials({this.username, this.password, this.apiKey});

  LoginFormCredentials copyWith({
    String? username,
    String? password,
    String? apiKey,
  }) {
    return LoginFormCredentials(
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  bool get isApiKeyAuth => apiKey != null && apiKey!.isNotEmpty;
}
