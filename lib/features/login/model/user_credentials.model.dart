class UserCredentials {
  final String? username;
  final String? password;

  UserCredentials({this.username, this.password});

  UserCredentials copyWith({String? username, String? password}) {
    return UserCredentials(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}
