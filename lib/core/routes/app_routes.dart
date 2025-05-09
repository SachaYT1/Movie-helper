import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../home_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildPageRouteWithTransition(
          const LoginScreen(),
          settings,
        );
      case register:
        return _buildPageRouteWithTransition(
          const RegistrationScreen(),
          settings,
        );
      case forgotPassword:
        return _buildPageRouteWithTransition(
          const ForgotPasswordScreen(),
          settings,
        );
      case home:
        return _buildPageRouteWithTransition(
          const HomePage(),
          settings,
        );
      default:
        return _buildPageRouteWithTransition(
          const LoginScreen(),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildPageRouteWithTransition(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var offsetAnimation = animation.drive(tween);

        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0),
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
