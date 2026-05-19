import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to .env values. Loaded once by [Env.load] in main().
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  // Sprint 2 placeholders (NAD-21)
  static String? get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  static String? get billplzApiKey => dotenv.env['BILLPLZ_API_KEY'];

  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required .env value "$key". '
        'Copy .env.example to .env and fill in the values.',
      );
    }
    return value;
  }
}
