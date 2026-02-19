import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/l10n/app_localizations.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Firebase & FCM
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    NotificationService.markInitFailed();
  }

  // Load saved preferences
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'tr';
  final savedFirstDay = prefs.getInt('first_day_of_week') ?? 1; // 1=Monday

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => Locale(savedLocale)),
        firstDayOfWeekProvider.overrideWith((ref) => savedFirstDay),
      ],
      child: const PdksApp(),
    ),
  );
}

class PdksApp extends ConsumerWidget {
  const PdksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PDKS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
