import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isAuthenticated => currentSession != null;

  static String get edgeFunctionBaseUrl => '${AppConstants.supabaseUrl}/functions/v1';

  static Map<String, String> get authHeaders => {
        'Authorization': 'Bearer ${currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      };
}
