import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Copy from: Supabase Dashboard → Project Settings → API
  static const String supabaseUrl =
      'https://stybxojmvkjhzxetdgkt.supabase.co';

  // Use only the publishable key or legacy anon key.
  static const String supabaseAnonKey =
      'sb_publishable_pI3lQ2LTL4n3TGW4gzV7jg_igKnIXO_';

  static Future<void> initialize() async {
    debugPrint(
      'Connected Supabase project: ${Uri.parse(supabaseUrl).host}',
    );

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}