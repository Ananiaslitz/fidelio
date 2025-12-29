import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Replace with environment variables or build config
  static const String url = 'https://wfjjfktyjwxyvwilccmg.supabase.co';
  static const String anonKey = 'sb_publishable_KB9NS4m8TEZnWRecZGuMjw_Pg5bBrFC';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
