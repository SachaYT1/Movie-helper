import 'package:flutter/material.dart';
import 'package:movie_helper/core/theme/app_theme.dart';
import 'package:movie_helper/features/auth/presentation/screens/registration_screen.dart';
import 'package:movie_helper/features/movies/di/dependency_injection.dart';
import 'package:movie_helper/home_page.dart';
import 'package:provider/provider.dart';
import 'package:movie_helper/features/movies/presentation/providers/movie_provider.dart';

void main() {
  setupDependencies();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => getIt<MovieProvider>(),
      )
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Helper',
      theme: AppTheme.darkTheme,
      home: const RegistrationScreen(),
    );
  }
}
