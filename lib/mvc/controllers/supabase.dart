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
      // TR: Başlatma hatalarını nazikçe ele al | EN: Handle initialization errors gracefully | RU: Аккуратно обработать ошибки инициализации
      debugPrint('Supabase initialization failed: $e');
      debugPrint('Please check your .env file and ensure you have valid Supabase credentials.');
      debugPrint('You can get your credentials from your Supabase project dashboard.');
      // TR: Sahte istemci oluştur veya çevrimdışı modu yönet | EN: Create mock client or handle offline mode | RU: Создать фиктивный клиент или обработать офлайн режим
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

  /// TR: Kullanıcıya ait sonuçları al | EN: Get results for a user | RU: Получить результаты пользователя
  Future<List<Map<String, dynamic>>> getUserResults(String userId) async {
    final response = await client
        .from('results')
        .select()
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// TR: Kullanıcıya ait tabloya sonuç ekle | EN: Insert result into shared table | RU: Вставить результат в общую таблицу
  Future<void> insertUserResult(String userId, Map<String, dynamic> result) async {
    await client.from('results').insert({
      ...result,
      'created_by': userId,
    });
  }

  /// TR: Metin tipine göre kullanıcı sonuçları | EN: Get results by text type | RU: Получить результаты по типу текста
  Future<List<Map<String, dynamic>>> getUserResultsByType(
    String userId, 
    String textType
  ) async {
    final response = await client
        .from('results')
        .select()
        .eq('text_type', textType)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// TR: Tüm kullanıcılar için metin tipine göre sonuçları getir | EN: Get results by text type for all users | RU: Получить результаты по типу текста для всех пользователей
  Future<List<Map<String, dynamic>>> getResultsByType(String textType) async {
    final response = await client
        .from('results')
        .select()
        .eq('text_type', textType)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  
}
