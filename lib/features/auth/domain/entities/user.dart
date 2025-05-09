class User {
  final int? id;
  final String username;
  final String email;
  final String? token;

  User({
    this.id,
    required this.username,
    required this.email,
    this.token,
  });

  @override
  String toString() => 'User(id: $id, username: $username, email: $email)';
}
