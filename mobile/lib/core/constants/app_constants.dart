import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Supabase — replace with your project credentials
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key-here');

  // Colors
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);
  static const Color accentColor = Color(0xFF26A69A);
  static const Color clockInColor = Color(0xFF43A047);
  static const Color clockOutColor = Color(0xFFE53935);
  static const Color mealReadyColor = Color(0xFFFFA726);
  static const Color overtimeColor = Color(0xFFAB47BC);
  static const Color leaveColor = Color(0xFF42A5F5);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Sizes
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double borderRadius = 12.0;
  static const double clockButtonSize = 160.0;
  static const double iconSizeSM = 20.0;
  static const double iconSizeMD = 24.0;
  static const double iconSizeLG = 32.0;

  // Shared Preferences Keys
  static const String prefLocale = 'locale';
  static const String prefThemeMode = 'theme_mode';
}
