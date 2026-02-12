import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // Supabase — loaded from .env at runtime
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Obsidian Theme Colors
  static const Color primaryColor = Color(0xFFF59E0B);   // amber-500
  static const Color primaryLight = Color(0xFFFBBF24);   // amber-400
  static const Color primaryDark = Color(0xFFD97706);    // amber-600
  static const Color accentColor = Color(0xFFF59E0B);    // amber-500

  // Semantic Colors
  static const Color clockInColor = Color(0xFF10B981);   // emerald-500
  static const Color clockOutColor = Color(0xFFF43F5E);  // rose-500
  static const Color mealReadyColor = Color(0xFFF59E0B); // amber-500
  static const Color overtimeColor = Color(0xFF8B5CF6);  // violet-500
  static const Color leaveColor = Color(0xFF0EA5E9);     // sky-500
  static const Color errorColor = Color(0xFFF43F5E);     // rose-500

  // Surface Colors (Obsidian)
  static const Color backgroundColor = Color(0xFF09090B);  // zinc-950
  static const Color surfaceColor = Color(0xFF18181B);     // zinc-900
  static const Color cardColor = Color(0xFF18181B);        // zinc-900
  static const Color inputColor = Color(0xFF27272A);       // zinc-800
  static const Color borderColor = Color(0xFF3F3F46);      // zinc-700

  // Text Colors
  static const Color textPrimary = Color(0xFFE4E4E7);    // zinc-200
  static const Color textSecondary = Color(0xFFA1A1AA);   // zinc-400
  static const Color textMuted = Color(0xFF71717A);       // zinc-500

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
