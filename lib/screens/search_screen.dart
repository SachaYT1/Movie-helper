import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:movie_helper/models/movie.dart';
import 'package:movie_helper/providers/movie_provider.dart';
import 'package:movie_helper/widgets/movie_card.dart';
import 'package:movie_helper/screens/movie_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool selectionMode; // Добавляем флаг режима выбора

  const SearchScreen({
    Key? key, 
    this.selectionMode = false, // По умолчанию режим выбора выключен
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      Provider.of<MovieProvider>(context, listen: false)
          .searchMovies(query)
          .then((_) {
        setState(() {
          _isSearching = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Выберите фильм' : 'Поиск фильмов'),
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Введите название фильма',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.requestFocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Кнопка поиска
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Искать'),
              ),
            ),
          ),

          // Индикатор загрузки или результаты поиска
          Expanded(
            child: Consumer<MovieProvider>(
              builder: (context, movieProvider, child) {
                if (movieProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (movieProvider.error.isNotEmpty) {
                  return Center(
                    child: Text(
                      movieProvider.error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final searchResults = movieProvider.searchResults;
                if (_isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (searchResults.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return const Center(
                    child: Text(
                      'Ничего не найдено. Попробуйте изменить запрос.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'Введите название фильма для поиска',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.5, // Увеличиваем высоту карточки
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = searchResults[index];
                    return Stack(
                      children: [
                        MovieCard(
                          movie: movie,
                          onTap: () {
                            if (widget.selectionMode) {
                              // В режиме выбора возвращаем фильм
                              Navigator.pop(context, movie);
                            } else {
                              // В обычном режиме открываем детали фильма
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MovieDetailsScreen(movie: movie),
                                ),
                              );
                            }
                          },
                        ),
                        // Добавляем кнопку выбора в режиме выбора
                        if (widget.selectionMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, movie);
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
