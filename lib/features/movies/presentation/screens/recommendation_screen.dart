import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_helper/features/auth/presentation/providers/auth_provider.dart';
import 'package:movie_helper/features/movies/domain/entities/movie.dart';
import 'package:movie_helper/features/movies/presentation/providers/movie_provider.dart';
import 'package:movie_helper/features/movies/presentation/widgets/movie_card.dart';
import 'package:movie_helper/features/movies/presentation/screens/movie_details_screen.dart';
import 'package:movie_helper/features/movies/presentation/screens/search_screen.dart';
import 'package:movie_helper/features/movies/presentation/providers/tutorial_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;

  // Keys for tutorial coach mark
  final GlobalKey _addMovieKey = GlobalKey();
  final GlobalKey _genresKey = GlobalKey();
  final GlobalKey _promptKey = GlobalKey();

  // ScrollController for auto-scrolling during tutorial
  final ScrollController _scrollController = ScrollController();

  // Tutorial service
  late TutorialService _tutorialService;

  @override
  void initState() {
    super.initState();
    // Загружаем жанры и похожие фильмы при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      movieProvider.loadGenres();

      // Load similar movies from backend if user is authenticated
      if (authProvider.isAuthenticated && authProvider.user?.id != null) {
        movieProvider.loadSimilarMoviesFromBackend();
      }

      // Initialize tutorial service
      _tutorialService = TutorialService(
        targetKeys: [_addMovieKey, _genresKey, _promptKey],
        scrollController: _scrollController,
        context: context,
      );
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showTutorial() {
    _tutorialService.startTutorial();
  }

  void _getRecommendations() {
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);

    if (movieProvider.selectedGenres.isEmpty &&
        movieProvider.similarMovies.isEmpty &&
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

    movieProvider
        .getRecommendations(
      query: _promptController.text.trim(),
    )
        .then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендации фильмов'),
        actions: [
          // Question mark button for tutorial
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTutorial,
            tooltip: 'Руководство',
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

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
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
                    if (movieProvider.similarMovies.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movieProvider.similarMovies.length,
                          itemBuilder: (context, index) {
                            final movie = movieProvider.similarMovies[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: MovieCard(
                                        key: ValueKey(
                                            'movie_${movie.id}_${movie.imdbId}'),
                                        movie: movie,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MovieDetailsScreen(
                                                      movie: movie),
                                            ),
                                          ).then((_) {
                                            // Reload similar movies when returning from details screen
                                            final authProvider =
                                                Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false);
                                            if (authProvider.isAuthenticated &&
                                                authProvider.user?.id != null) {
                                              movieProvider
                                                  .loadSimilarMoviesFromBackend();
                                            }
                                          });
                                        },
                                        compact: false,
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
                                        onPressed: () => movieProvider
                                            .removeSimilarMovie(movie),
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
                              const Icon(Icons.movie,
                                  size: 32, color: Colors.grey),
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
                      key: _addMovieKey,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SearchScreen(selectionMode: true),
                            ),
                          ).then((value) async {
                            if (value != null && value is Movie) {
                              // Display a snackbar to indicate movie is being added
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Добавление фильма ${value.title}...'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );

                              // Add the movie
                              await movieProvider.addSimilarMovie(value);

                              // Show success message
                              if (movieProvider.error.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Фильм ${value.title} добавлен'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
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
                    Container(
                      key: _genresKey,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: movieProvider.genres.map((genre) {
                          final isSelected =
                              movieProvider.selectedGenres.contains(genre.name);
                          return FilterChip(
                            label: Text(genre.name),
                            selected: isSelected,
                            onSelected: (_) =>
                                movieProvider.toggleGenre(genre.name),
                            // backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                          );
                        }).toList(),
                      ),
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
                    Container(
                      key: _promptKey,
                      child: TextField(
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
                    ),

                    const SizedBox(height: 16),

                    // Переключатель для ML-рекомендаций
                    Row(
                      children: [
                        const Text(
                          'Использовать ML-рекомендации:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        Switch(
                          value: movieProvider.useMlRecommendations,
                          onChanged: (value) {
                            movieProvider.toggleMlRecommendations();
                          },
                        ),
                      ],
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
                              childAspectRatio: 0.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: movieProvider.recommendedMovies.length,
                            itemBuilder: (context, index) {
                              final movie =
                                  movieProvider.recommendedMovies[index];
                              return SizedBox(
                                height: 230,
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
              ),

              // Show loading overlay when adding/loading movies
              if (movieProvider.isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
