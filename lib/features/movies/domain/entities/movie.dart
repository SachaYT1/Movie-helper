class Movie {
  final int id;
  final String imdbId;
  final String title;
  final String overview;
  final String posterPath;
  final List<String> genres;
  final double voteAverage;
  final String releaseDate;
  final String year;
  final String director;
  final String actors;

  Movie({
    required this.id,
    required this.imdbId,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.genres,
    required this.voteAverage,
    required this.releaseDate,
    required this.year,
    required this.director,
    required this.actors,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<String> genresList = [];
    if (json['genres'] != null) {
      genresList =
          List<String>.from(json['genres'].map((genre) => genre['name']));
    } else if (json['genre_ids'] != null) {
      // Здесь в реальном приложении нужно будет преобразовать ID жанров в названия
      genresList =
          List<String>.from(json['genre_ids'].map((id) => id.toString()));
    }

    return Movie(
      id: json['id'],
      imdbId: json['imdb_id'] ?? '',
      title: json['title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      genres: genresList,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] ?? '',
      year: json['year'] ?? '',
      director: json['director'] ?? '',
      actors: json['actors'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imdb_id': imdbId,
      'title': title,
      'overview': overview,
      'poster_path': posterPath,
      'genres': genres,
      'vote_average': voteAverage,
      'release_date': releaseDate,
      'year': year,
      'director': director,
      'actors': actors,
    };
  }
}
