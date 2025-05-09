import 'package:movie_helper/features/auth/data/datasources/auth_api_client.dart';
import 'package:movie_helper/features/auth/domain/entities/user.dart';
import 'package:movie_helper/features/auth/domain/repositories/repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiClient apiClient;

  AuthRepositoryImpl({required this.apiClient});

  @override
  Future<User> login(String usernameOrEmail, String password) async {
    return await apiClient.login(usernameOrEmail, password);
  }

  @override
  Future<User> register(String username, String email, String password) async {
    return await apiClient.register(username, email, password);
  }

  @override
  Future<bool> isLoggedIn() async {
    return await apiClient.isLoggedIn();
  }

  @override
  Future<void> logout() async {
    await apiClient.logout();
  }

  @override
  Future<void> resetPassword(String email) async {
    await apiClient.resetPassword(email);
  }

  Future<User?> getCurrentUser() async {
    return await apiClient.getCurrentUser();
  }
}
