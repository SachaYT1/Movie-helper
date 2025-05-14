import 'package:flutter/foundation.dart';
import 'package:movie_helper/features/auth/data/datasources/auth_api_client.dart';
import 'package:movie_helper/features/auth/domain/entities/user.dart';
import 'package:movie_helper/features/auth/domain/repositories/repository.dart';
import 'package:movie_helper/core/utils/logger.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    // Check if user is already logged in
    _checkAuthStatus();
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  Future<void> _checkAuthStatus() async {
    try {
      log.d('Checking authentication status');
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        log.i('User is logged in');
        // Проверяем, поддерживает ли репозиторий метод getCurrentUser
        if (_authRepository is AuthRepositoryWithUserData) {
          try {
            _user = await _authRepository.getCurrentUser();
            if (_user != null) {
              log.i('User data loaded: ${_user?.username}');
              _status = AuthStatus.authenticated;
            } else {
              log.w('User is logged in but data is null');
              _status = AuthStatus.unauthenticated;
            }
          } catch (e) {
            log.e('Failed to load user data', e);
            _status = AuthStatus.unauthenticated;
            _errorMessage = 'Failed to load user data: ${e.toString()}';
          }
        } else {
          log.i('Repository does not support getCurrentUser method');
          _status = AuthStatus.authenticated;
        }
      } else {
        log.i('User is not logged in');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      log.e('Error checking auth status', e);
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<bool> register(String username, String email, String password) async {
    log.i('Attempting to register: $username, $email');
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(username, email, password);
      log.i('Registration successful for: $username');
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      log.e('Registration failed', e);
      _status = AuthStatus.error;
      _errorMessage = e is AuthException
          ? e.message
          : 'Failed to register: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    log.i('Attempting to login: $usernameOrEmail');
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(usernameOrEmail, password);
      log.i('Login successful for: $usernameOrEmail');
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      log.e('Login failed', e);
      _status = AuthStatus.error;
      _errorMessage =
          e is AuthException ? e.message : 'Failed to login: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    log.i('Logging out user: ${_user?.username}');
    try {
      await _authRepository.logout();
      log.i('Logout successful');
    } catch (e) {
      log.e('Error during logout', e);
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    log.i('Attempting to reset password for: $email');
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
      log.i('Password reset email sent to: $email');
      notifyListeners();
      return true;
    } catch (e) {
      log.e('Password reset failed', e);
      _errorMessage = e is AuthException
          ? e.message
          : 'Failed to reset password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
