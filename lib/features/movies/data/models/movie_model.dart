// lib/features/movies/data/models/movie_model.dart
import '../../domain/entities/movie.dart';

class MovieModel extends Movie {
  MovieModel({
    required super.id,
    required super.imdbId,
    required super.title,
    required super.overview,
    required super.posterPath,
    required super.genres,
    required super.voteAverage,
    required super.releaseDate,
    required super.year,
    required super.director,
    required super.actors,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    double rating = 0.0;
    if (json['imdbRating'] != null && json['imdbRating'] != 'N/A') {
      rating = double.tryParse(json['imdbRating']) ?? 0.0;
    }

    List<String> genres = [];
    if (json['Genre'] != null && json['Genre'] != 'N/A') {
      genres = json['Genre'].split(', ');
    }

    return MovieModel(
      id: int.tryParse(json['imdbID']?.replaceAll('tt', '') ?? '0') ?? 0,
      imdbId: json['imdbID'] ?? '',
      title: json['Title'] ?? 'Без названия',
      overview: json['Plot'] != 'N/A' ? json['Plot'] : '',
      posterPath: json['Poster'] != 'N/A' ? json['Poster'] : '',
      genres: genres,
      voteAverage: rating,
      releaseDate: json['Released'] != 'N/A' ? json['Released'] : '',
      year: json['Year'] != 'N/A' ? json['Year'] : '',
      director: json['Director'] != 'N/A' ? json['Director'] : '',
      actors: json['Actors'] != 'N/A' ? json['Actors'] : '',
    );
  }
}