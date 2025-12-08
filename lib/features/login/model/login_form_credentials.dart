class LoginFormCredentials {
  final String? username;
  final String? password;
  final Map<String, String> customHeaders;

  LoginFormCredentials({
    this.username,
    this.password,
    this.customHeaders = const {},
  });

  LoginFormCredentials copyWith({
    String? username,
    String? password,
    Map<String, String>? customHeaders,
  }) {
    return LoginFormCredentials(
      username: username ?? this.username,
      password: password ?? this.password,
      customHeaders: customHeaders ?? this.customHeaders,
    );
  }
}
