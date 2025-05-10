// lib/features/movies/di/dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:movie_helper/features/auth/presentation/providers/auth_provider.dart';
import 'package:movie_helper/features/movies/domain/usecases/get_recommendation_use_case.dart';
import 'package:movie_helper/features/movies/domain/usecases/search_movie_use_case.dart';
import '../data/datasources/movie_remote_datasource.dart';
import '../data/datasources/similar_movies_datasource.dart';
import '../data/repositories/movie_repository_impl.dart';
import '../domain/repositories/movie_repository.dart';
import '../domain/usecases/get_genres_use_case.dart';
import '../domain/usecases/get_user_similar_movies_use_case.dart';
import '../domain/usecases/add_similar_movie_use_case.dart';
import '../domain/usecases/remove_similar_movie_use_case.dart';
import '../presentation/providers/movie_provider.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Data sources
  getIt.registerLazySingleton<MovieRemoteDataSource>(
    () => MovieRemoteDataSource(),
  );

  getIt.registerLazySingleton<SimilarMoviesDataSource>(
    () => SimilarMoviesDataSource(),
  );

  // Repositories
  getIt.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(
      remoteDataSource: getIt(),
      similarMoviesDataSource: getIt(),
    ),
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
  getIt.registerLazySingleton<GetUserSimilarMoviesUseCase>(
    () => GetUserSimilarMoviesUseCase(getIt()),
  );
  getIt.registerLazySingleton<AddSimilarMovieUseCase>(
    () => AddSimilarMovieUseCase(getIt()),
  );
  getIt.registerLazySingleton<RemoveSimilarMovieUseCase>(
    () => RemoveSimilarMovieUseCase(getIt()),
  );

  // Providers
  getIt.registerFactory<MovieProvider>(
    () {
      // Get the auth provider to get the user ID
      final authProvider = getIt<AuthProvider>();
      final userId = authProvider.user?.id;

      return MovieProvider(
        searchMoviesUseCase: getIt(),
        getRecommendationsUseCase: getIt(),
        getGenresUseCase: getIt(),
        getUserSimilarMoviesUseCase: getIt(),
        addSimilarMovieUseCase: getIt(),
        removeSimilarMovieUseCase: getIt(),
        userId: userId,
        authProvider: authProvider,
      );
    },
  );
}
