import 'package:flutter/material.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/fridge/presentation/fridge_list_screen.dart';
import '../features/shelf/presentation/shelf_list_screen.dart';
import '../features/recipes/presentation/cook_ideas_screen.dart';
import 'package:animations/animations.dart';

class AppRoutes {
  static const home = '/';
  static const fridge = '/fridge';
  static const shelf = '/shelf';
  static const cook = '/cook';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen());
      case fridge:
        return _buildRoute(const FridgeListScreen());
      case shelf:
        return _buildRoute(const ShelfListScreen());
      case cook:
        return _buildRoute(const CookIdeasScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static Route<T> fadeThroughRoute<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }

  static Route<dynamic> _buildRoute(Widget page) {
    return fadeThroughRoute(page: page);
  }
}
