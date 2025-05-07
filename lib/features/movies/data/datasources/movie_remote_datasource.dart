// lib/features/movies/data/datasources/movie_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:movie_helper/core/constants/app_constants.dart';


class MovieRemoteDataSource {
  final Dio _dio;
  final String _baseUrl;
  final String _apiKey;

  MovieRemoteDataSource({
    Dio? dio,
    String? baseUrl,
    String? apiKey,
  })  : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? MovieConstants.omdbApiUrl,
        _apiKey = apiKey ?? MovieConstants.omdbApiKey;

  Future<Map<String, dynamic>> searchMovies(String query) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'apikey': _apiKey,
        's': query,
        'type': 'movie',
        'page': 1,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMovieDetails(String imdbId) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'apikey': _apiKey,
        'i': imdbId,
        'plot': 'full',
      },
    );
    return response.data;
  }
}