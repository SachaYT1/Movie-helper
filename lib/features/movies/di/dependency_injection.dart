// lib/features/movies/di/dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_recommendation_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/search_movie_use_case.dart';
import '../data/datasources/movie_remote_datasource.dart';
import '../data/repositories/movie_repository_impl.dart';
import '../domain/repositories/movie_repository.dart';
import '../domain/usecases/get_genres_use_case.dart';
import '../presentation/providers/movie_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Data sources
  getIt.registerLazySingleton<MovieRemoteDataSource>(
    () => MovieRemoteDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(remoteDataSource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton<SearchMoviesUseCase>(
    () => SearchMoviesUseCase(getIt()),
  );
  getIt.registerLazySingleton<GetRecommendationsUseCase>(
    () => GetRecommendationsUseCase(getIt()),
  );
  getIt.registerLazySingleton<GetGenresUseCase>(
    () => GetGenresUseCase(getIt()),
  );

  // Providers
  getIt.registerFactory<MovieProvider>(
    () => MovieProvider(
      searchMoviesUseCase: getIt(),
      getRecommendationsUseCase: getIt(),
      getGenresUseCase: getIt(),
    ),
  );
}