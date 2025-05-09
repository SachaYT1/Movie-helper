import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException: $message (Code: $statusCode)';
}

class AuthApiClient {
  final String baseUrl;
  final http.Client client;

  AuthApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<UserModel> register(
      String username, String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        // The API doesn't return user data, so we create a user from the provided data
        // In a real app, it would be better if the API returned the created user
        final userModel = UserModel(
          username: username,
          email: email,
        );

        // Save auth state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userModel.toJson()));

        return userModel;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['error'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error during registration: ${e.toString()}');
    }
  }

  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': usernameOrEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userModel = UserModel.fromJson(data);

        // Save auth state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userModel.toJson()));

        return userModel;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['error'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error during login: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw AuthException(
          errorData['error'] ?? 'Password reset failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
          'Network error during password reset: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}
