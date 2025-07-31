import 'package:flutter/material.dart';
import 'package:opennow/screens/splash/splash_screen.dart';
import 'package:opennow/screens/login/login_screen.dart';
import 'package:opennow/screens/login/otp_screen.dart';
import 'package:opennow/screens/owner/owner_dashboard.dart';
import 'package:opennow/screens/owner/register_shop_screen.dart';
import 'package:opennow/screens/customer/customer_dashboard.dart';
import 'package:opennow/screens/customer/map_view_screen.dart';
import 'package:opennow/screens/customer/shop_search_screen.dart';
import 'package:opennow/screens/profile/profile_screen.dart';

/// Application routes configuration
/// Defines all named routes used for navigation throughout the app
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String ownerDashboard = '/owner-dashboard';
  static const String registerShop = '/register-shop';
  static const String customerDashboard = '/customer-dashboard';
  static const String mapView = '/map-view';
  static const String shopSearch = '/shop-search';
  static const String profile = '/profile';

  /// Map of route names to their corresponding widget builders
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    otp: (context) => const OtpScreen(),
    ownerDashboard: (context) => const OwnerDashboard(),
    registerShop: (context) => const RegisterShopScreen(),
    customerDashboard: (context) => const CustomerDashboard(),
    mapView: (context) => const MapViewScreen(),
    shopSearch: (context) => const ShopSearchScreen(),
    profile: (context) => const ProfileScreen(),
  };

  /// Navigate to a named route
  static Future<dynamic> pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate to a named route and remove all previous routes
  static Future<dynamic> pushNamedAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace current route with a new one
  static Future<dynamic> pushReplacement(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  /// Pop current route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Check if we can pop (has previous route)
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}