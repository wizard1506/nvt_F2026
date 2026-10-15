import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://byfgqevdyxtdlochmyml.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZmdxZXZkeXh0ZGxvY2hteW1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNzM2MjAsImV4cCI6MjEwNjg0OTYyMH0.GM_741jiftEcK87J6D-1iymj7L5NB1JfmCxfD1fD0S8';
  static const int defaultRolAsesor = 4;

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    _initialized = true;
  }
}
