import 'package:movie_helper/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Registers a new user
  /// Returns the registered user if successful
  /// Throws exception if registration fails
  Future<User> register(String username, String email, String password);

  /// Authenticates a user
  /// Returns the authenticated user if successful
  /// Throws exception if authentication fails
  Future<User> login(String usernameOrEmail, String password);

  /// Checks if the user is logged in
  Future<bool> isLoggedIn();

  /// Logs out the current user
  Future<void> logout();

  /// Sends password reset email
  Future<void> resetPassword(String email);
}
