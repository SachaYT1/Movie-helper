import 'package:flutter/foundation.dart';
import 'package:movie_helper/features/auth/data/datasources/auth_api_client.dart';
import 'package:movie_helper/features/auth/domain/entities/user.dart';
import 'package:movie_helper/features/auth/domain/repositories/repository.dart';

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
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        // Если репозиторий имеет метод getCurrentUser, используем его
        if (_authRepository is dynamic) {
          try {
            _user = await (_authRepository as dynamic).getCurrentUser();
            if (_user != null) {
              _status = AuthStatus.authenticated;
            } else {
              _status = AuthStatus.unauthenticated;
            }
          } catch (e) {
            _status = AuthStatus.unauthenticated;
            _errorMessage = 'Failed to load user data: ${e.toString()}';
          }
        } else {
          _status = AuthStatus.authenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<bool> register(String username, String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(username, email, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e is AuthException
          ? e.message
          : 'Failed to register: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(usernameOrEmail, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage =
          e is AuthException ? e.message : 'Failed to login: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AuthException
          ? e.message
          : 'Failed to reset password: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
