import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../../controllers/auth_service.dart';

class RawScreen extends StatefulWidget {
  const RawScreen({super.key});

  @override
  State<RawScreen> createState() => _RawScreenState();
}

class _RawScreenState extends State<RawScreen> {
  List<Map<String, dynamic>> all = [];
  List<Map<String, dynamic>> filtered = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_applyFilter);
  }

  Future<void> _load() async {
    try {
      // TR: Global tablo yerine kullanıcıya özel sonuçları kullan | EN: Use user-specific results instead of global table | RU: Используй результаты пользователя вместо общей таблицы
      final authService = AuthService();
      final userResults = await authService.getUserResults();
      
      setState(() {
        all = userResults;
        filtered = all;
      });
    } catch (e) {
      // TR: Eksik tabloyu gracefully ele al | EN: Handle missing table gracefully | RU: Корректно обработай отсутствие таблицы
      setState(() {
        all = [];
        filtered = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı verileri yüklenemedi: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    final q = _search.text.toLowerCase();
    setState(() {
      filtered = all.where((row) {
        final text = (row['text'] ?? '').toString().toLowerCase();
        final file = (row['file'] ?? '').toString().toLowerCase();
        return text.contains(q) || file.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      drawer: const AppDrawer(currentRoute: '/ocr/raw'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Ara (text/file)",
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final r = filtered[i];
                return ListTile(
                  title: Text(r['text'] ?? ''),
                  subtitle: Text(
                    "file: ${r['file']} • conf: ${r['confidence']}",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
