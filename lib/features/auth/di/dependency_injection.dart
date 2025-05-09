import 'package:get_it/get_it.dart';
import 'package:movie_helper/features/auth/data/datasources/auth_api_client.dart';
import 'package:movie_helper/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:movie_helper/features/auth/domain/repositories/repository.dart';
import 'package:movie_helper/features/auth/presentation/providers/auth_provider.dart';

final GetIt getIt = GetIt.instance;

void setupAuthDependencies() {
  // Set up API client
  getIt.registerLazySingleton<AuthApiClient>(
    () => AuthApiClient(
      baseUrl: 'http://127.0.0.1:5000', // change to your actual server URL
    ),
  );

  // Set up repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: getIt<AuthApiClient>(),
    ),
  );

  // Set up provider
  getIt.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      authRepository: getIt<AuthRepository>(),
    ),
  );
}
