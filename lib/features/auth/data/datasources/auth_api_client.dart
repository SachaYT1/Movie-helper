import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

import 'package:movie_helper/core/utils/logger.dart';

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
      log.d('Registering user: $username, $email');
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
        log.d('User registered successfully');
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
        log.e('Registration failed: ${errorData['error']}');
        throw AuthException(
          errorData['error'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      log.e('Registration failed: ${e.toString()}');
      if (e is AuthException) rethrow;
      throw AuthException('Network error during registration: ${e.toString()}');
    }
  }

  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      log.d('Logging in user: $usernameOrEmail');
      final response = await client.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': usernameOrEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        log.d('Login successful');
        final data = jsonDecode(response.body);
        final userModel = UserModel.fromJson(data);

        // Save auth state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userModel.toJson()));

        return userModel;
      } else {
        final errorData = jsonDecode(response.body);
        log.e('Login failed: ${errorData['error']}');
        throw AuthException(
          errorData['error'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      log.e('Login failed: ${e.toString()}');
      throw AuthException('Network error during login: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      log.d('Resetting password for email: $email');
      final response = await client.post(
        Uri.parse('$baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        log.e('Password reset failed: ${errorData['error']}');
        throw AuthException(
          errorData['error'] ?? 'Password reset failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      log.e('Password reset failed: ${e.toString()}');
      throw AuthException(
          'Network error during password reset: ${e.toString()}');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    log.d('Checking if user is logged in');
    return prefs.containsKey('user');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      try {
        log.d('Getting current user');
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        log.e('Error getting current user: ${e.toString()}');
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    log.d('Logging out user');
    await prefs.remove('user');
  }
}
