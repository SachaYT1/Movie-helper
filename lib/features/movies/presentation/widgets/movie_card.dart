import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movie_helper/features/movies/domain/entities/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool compact;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Постер фильма
            AspectRatio(
              aspectRatio: 3 / 4, // Сохраняем соотношение сторон постера
              child: movie.posterPath.isNotEmpty && movie.posterPath != 'N/A'
                  ? CachedNetworkImage(
                      imageUrl: movie.posterPath,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(Icons.movie, size: 50),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.movie, size: 50),
                      ),
                    ),
            ),

            // Информация о фильме
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название фильма
                    Text(
                      movie.title,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // // Год выпуска
                    // if (movie.year.isNotEmpty)
                    //   Text(
                    //     movie.year,
                    //     style: TextStyle(
                    //       fontSize: compact ? 10 : 12,
                    //       color: Colors.grey[600],
                    //     ),
                    //   ),
                    // if (!compact) const SizedBox(height: 4),

                    // Рейтинг - показываем только если не компактный режим или есть место
                    if (!compact || movie.year.isEmpty)
                      Row(
                        children: [
                          RatingBar.builder(
                            initialRating:
                                movie.voteAverage / 2, // Преобразуем из 10 в 5
                            minRating: 0,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: compact ? 10 : 12,
                            ignoreGestures: true,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (_) {},
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${movie.voteAverage.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: compact ? 9 : 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                    // Показываем жанры только если не компактный режим
                    if (!compact && movie.genres.isNotEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            movie.genres.take(2).join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
