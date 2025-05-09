import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_helper/features/movies/domain/entities/movie.dart';
import 'package:movie_helper/features/movies/presentation/providers/movie_provider.dart';
import 'package:movie_helper/features/movies/presentation/widgets/movie_card.dart';
import 'package:movie_helper/features/movies/presentation/screens/movie_details_screen.dart';
import 'package:movie_helper/features/movies/presentation/screens/search_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _selectedGenres = [];
  final List<Movie> _similarMovies = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Загружаем жанры при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MovieProvider>(context, listen: false).loadGenres();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _getRecommendations() {
    if (_selectedGenres.isEmpty &&
        _similarMovies.isEmpty &&
        _promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Пожалуйста, выберите хотя бы один критерий для рекомендаций'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Provider.of<MovieProvider>(context, listen: false)
        .getRecommendations(
      similarMovieIds: _similarMovies.map((m) => m.imdbId).toList(),
      genres: _selectedGenres,
      query: _promptController.text.trim(),
    )
        .then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _addSimilarMovie(Movie movie) {
    if (!_similarMovies.any((m) => m.imdbId == movie.imdbId)) {
      setState(() {
        _similarMovies.add(movie);
      });
    }
  }

  void _removeSimilarMovie(Movie movie) {
    setState(() {
      _similarMovies.removeWhere((m) => m.imdbId == movie.imdbId);
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации фильмов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          if (movieProvider.isLoading && movieProvider.genres.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Секция с похожими фильмами
                const Text(
                  'Похожие фильмы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте фильмы, похожие на которые вы хотите найти',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Список выбранных похожих фильмов
                if (_similarMovies.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _similarMovies.length,
                      itemBuilder: (context, index) {
                        final movie = _similarMovies[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: 130,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: MovieCard(
                                    movie: movie,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MovieDetailsScreen(movie: movie),
                                        ),
                                      );
                                    },
                                    compact: true,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _removeSimilarMovie(movie),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.movie, size: 32, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Нет выбранных фильмов',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Кнопка для добавления похожих фильмов
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SearchScreen(selectionMode: true),
                        ),
                      ).then((value) {
                        if (value != null && value is Movie) {
                          _addSimilarMovie(value);
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить фильм'),
                  ),
                ),

                const SizedBox(height: 24),

                // Секция с жанрами
                const Text(
                  'Жанры',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Выберите интересующие вас жанры',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Список жанров
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movieProvider.genres.map((genre) {
                    final isSelected = _selectedGenres.contains(genre.name);
                    return FilterChip(
                      label: Text(genre.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleGenre(genre.name),
                      // backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Секция с текстовым описанием
                const Text(
                  'Описание',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Опишите, какой фильм вы хотите посмотреть',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Поле для ввода описания
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Например: "Хочу посмотреть что-то захватывающее с неожиданной концовкой"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Кнопка для получения рекомендаций
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _getRecommendations,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Получить рекомендации'),
                  ),
                ),

                const SizedBox(height: 24),

                // Результаты рекомендаций
                if (movieProvider.recommendedMovies.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Рекомендуемые фильмы',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.45,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: movieProvider.recommendedMovies.length,
                        itemBuilder: (context, index) {
                          final movie = movieProvider.recommendedMovies[index];
                          return SizedBox(
                            height: 280,
                            child: MovieCard(
                              movie: movie,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MovieDetailsScreen(movie: movie),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
