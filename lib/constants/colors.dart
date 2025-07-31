import 'package:flutter/material.dart';

/// Application color palette
/// Defines all colors used throughout the app for consistency
class AppColors {
  /// Primary brand color - used for main actions and branding
  static const Color primary = Color(0xFF2196F3);
  
  /// Secondary color - used for accents and highlights
  static const Color secondary = Color(0xFF03DAC6);
  
  /// Success color - used for positive actions and open shops
  static const Color success = Color(0xFF4CAF50);
  
  /// Error color - used for errors and closed shops
  static const Color error = Color(0xFFF44336);
  
  /// Warning color - used for warnings and alerts
  static const Color warning = Color(0xFFFF9800);
  
  /// Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  
  /// Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  
  /// Neutral colors
  static const Color grey = Color(0xFFE0E0E0);
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF424242);
  
  /// Shop status colors
  static const Color shopOpen = success;
  static const Color shopClosed = error;
  static const Color shopUnknown = Color(0xFF9E9E9E);
  
  /// Map marker colors
  static const Color markerOpen = success;
  static const Color markerClosed = error;
  static const Color markerSelected = Color(0xFF9C27B0);
}