import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // Supabase — loaded from .env at runtime
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Primary Colors (Indigo/Purple)
  static const Color primaryColor = Color(0xFF6C5CE7);    // indigo accent
  static const Color primaryLight = Color(0xFF7E6FF0);
  static const Color primaryDark = Color(0xFF5A4BD6);
  static const Color accentColor = Color(0xFF6C5CE7);

  // Semantic Colors
  static const Color clockInColor = Color(0xFF10B981);    // emerald-500
  static const Color clockOutColor = Color(0xFFEF4444);   // red-500
  static const Color mealReadyColor = Color(0xFFF59E0B);  // amber-500
  static const Color overtimeColor = Color(0xFF8B5CF6);   // violet-500
  static const Color holidayColor = Color(0xFFEC4899);     // pink-500
  static const Color leaveColor = Color(0xFFF59E0B);      // amber-500 (yellow)
  static const Color sickLeaveColor = Color(0xFFF59E0B);  // amber-500 (yellow)
  static const Color errorColor = Color(0xFFEF4444);      // red-500
  static const Color warningColor = Color(0xFFF59E0B);    // amber-500
  static const Color onTimeColor = Color(0xFF10B981);     // green
  static const Color lateColor = Color(0xFFEF4444);       // red

  // Shift status colors
  static const Color fullShiftColor = Color(0xFF10B981);   // green
  static const Color overtimeShiftColor = Color(0xFF059669); // emerald-600 (green)
  static const Color missingShiftColor = Color(0xFFEF4444);  // red

  // Surface Colors (Dark Navy Theme)
  static const Color backgroundColor = Color(0xFF0A0E1A);   // deepest
  static const Color surfaceColor = Color(0xFF0F1428);       // scaffold
  static const Color cardColor = Color(0xFF161B2E);          // elevated surfaces
  static const Color cardLightColor = Color(0xFF1C2237);     // bottom sheets, inputs
  static const Color inputColor = Color(0xFF1C2237);         // input fields
  static const Color borderColor = Color(0xFF252B40);        // dividers

  // Text Colors
  static const Color textPrimary = Color(0xFFEEEFF5);     // white-ish
  static const Color textSecondary = Color(0xFF9BA1B7);    // medium gray
  static const Color textMuted = Color(0xFF5C6380);        // subtle gray

  // Sizes
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double borderRadius = 16.0;
  static const double borderRadiusSM = 12.0;
  static const double clockButtonSize = 180.0;
  static const double iconSizeSM = 20.0;
  static const double iconSizeMD = 24.0;
  static const double iconSizeLG = 32.0;

  // Shared Preferences Keys
  static const String prefLocale = 'locale';
  static const String prefThemeMode = 'theme_mode';
  static const String prefFirstDayOfWeek = 'first_day_of_week';
}
