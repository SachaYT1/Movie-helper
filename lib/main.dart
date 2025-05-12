import 'package:flutter/material.dart';
import 'package:movie_helper/core/theme/app_theme.dart';
import 'package:movie_helper/features/auth/di/dependency_injection.dart'
    as auth_di;
import 'package:movie_helper/features/movies/di/dependency_injection.dart';
import 'package:movie_helper/home_page.dart';
import 'package:provider/provider.dart';
import 'package:movie_helper/features/movies/presentation/providers/movie_provider.dart';
import 'package:movie_helper/features/movies/presentation/providers/feedback_provider.dart';
import 'package:movie_helper/features/auth/presentation/providers/auth_provider.dart';
import 'package:movie_helper/core/routes/app_routes.dart';
import 'package:movie_helper/features/auth/presentation/screens/login_screen.dart';

void main() {
  // Setup dependencies
  setupDependencies();
  auth_di.setupAuthDependencies();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => getIt<MovieProvider>(),
      ),
      ChangeNotifierProvider(
        create: (_) => getIt<FeedbackProvider>(),
      ),
      ChangeNotifierProvider(
        create: (_) => auth_di.getIt<AuthProvider>(),
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Movie Helper',
      theme: AppTheme.darkTheme,
      home: authProvider.status == AuthStatus.initial
          ? const LoadingScreen()
          : authProvider.isAuthenticated
              ? const HomePage()
              : const LoginScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
