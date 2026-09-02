import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const projectUrl = 'https://stybxojmvkjhzxetdgkt.supabase.co';
  static const publishableKey =
      'sb_publishable_pI3lQ2LTL4n3TGW4gzV7jg_igKnIXO_';

  static Future<void> initialize() async {
    await Supabase.initialize(url: projectUrl, publishableKey: publishableKey);
  }
}
