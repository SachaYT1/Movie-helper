import 'package:movie_helper/features/auth/domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    super.id,
    required super.username,
    required super.email,
    super.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      username: json['login'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'login': username,
      'email': email,
      'token': token,
    };
  }

  factory UserModel.fromUser(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      token: user.token,
    );
  }
}
