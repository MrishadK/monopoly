import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Centralized Supabase credentials.
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '<url>';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '<key>';
}
