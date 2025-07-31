import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/otp_screen.dart';
import 'screens/owner/owner_dashboard.dart';
import 'screens/owner/register_shop_screen.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/customer/map_view_screen.dart';
import 'screens/customer/shop_search_screen.dart';
import 'screens/profile/profile_screen.dart';

class Routes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String ownerDashboard = '/owner/dashboard';
  static const String registerShop = '/owner/register-shop';
  static const String customerDashboard = '/customer/dashboard';
  static const String mapView = '/customer/map-view';
  static const String shopSearch = '/customer/shop-search';
  static const String profile = '/profile';

  // Get home route based on user role
  static Widget getHomeRoute(UserRole? role) {
    switch (role) {
      case UserRole.owner:
        return const OwnerDashboard();
      case UserRole.customer:
        return const CustomerDashboard();
      default:
        return const LoginScreen();
    }
  }

  // Generate routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      
      case otp:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OTPScreen(
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
        );
      
      case ownerDashboard:
        return MaterialPageRoute(
          builder: (_) => const OwnerDashboard(),
        );
      
      case registerShop:
        return MaterialPageRoute(
          builder: (_) => const RegisterShopScreen(),
        );
      
      case customerDashboard:
        return MaterialPageRoute(
          builder: (_) => const CustomerDashboard(),
        );
      
      case mapView:
        return MaterialPageRoute(
          builder: (_) => const MapViewScreen(),
        );
      
      case shopSearch:
        return MaterialPageRoute(
          builder: (_) => const ShopSearchScreen(),
        );
      
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }

  // Navigate to screen
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // Navigate and replace current screen
  static Future<T?> navigateToReplacement<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // Navigate and clear all previous screens
  static Future<T?> navigateToAndClear<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Go back
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  // Go back with result
  static void goBackWithResult<T>(BuildContext context, T result) {
    Navigator.pop(context, result);
  }
}