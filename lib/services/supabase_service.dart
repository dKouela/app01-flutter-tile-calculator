import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    _client ??= Supabase.instance.client;
    return _client!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      anonKey: Constants.supabaseAnonKey,
      debug: false,
    );
  }

  static bool get isInitialized => _client != null;
}