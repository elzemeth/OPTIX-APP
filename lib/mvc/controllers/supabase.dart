import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient client;

  Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");

      final url = dotenv.env['SUPABASE_URL'];
      final key = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null || key == null) {
        throw Exception("Supabase URL or Key not found in .env file. Please check your .env file and ensure SUPABASE_URL and SUPABASE_ANON_KEY are set correctly.");
      }

      if (url == 'your_supabase_project_url_here' || key == 'your_supabase_anon_key_here') {
        throw Exception("Please update your .env file with actual Supabase credentials. Current values are placeholders.");
      }

      await Supabase.initialize(url: url, anonKey: key);
      client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      // Handle initialization errors gracefully
      debugPrint('Supabase initialization failed: $e');
      debugPrint('Please check your .env file and ensure you have valid Supabase credentials.');
      debugPrint('You can get your credentials from your Supabase project dashboard.');
      // Create a mock client or handle offline mode
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchResults() async {
    final res = await client
        .from('results')
        .select();
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await client.from('users').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addUser(String username, String email) async {
    await client.from('users').insert({'username': username, 'email': email});
  }

  /// Get user-specific results from their table
  Future<List<Map<String, dynamic>>> getUserResults(String userId) async {
    final tableName = 'user_results_$userId';
    final response = await client
        .from(tableName)
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Insert result into user-specific table
  Future<void> insertUserResult(String userId, Map<String, dynamic> result) async {
    final tableName = 'user_results_$userId';
    await client.from(tableName).insert(result);
  }

  /// Get results by text type from user-specific table
  Future<List<Map<String, dynamic>>> getUserResultsByType(
    String userId, 
    String textType
  ) async {
    final tableName = 'user_results_$userId';
    final response = await client
        .from(tableName)
        .select()
        .eq('text_type', textType)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
}
