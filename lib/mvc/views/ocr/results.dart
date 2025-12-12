import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bucket_card.dart' as bucket_card;
import '../../controllers/auth_service.dart';
import '../../controllers/supabase.dart';
import '../../models/app_strings.dart';
import 'package:design/constants/app_constants.dart';

class Results extends StatefulWidget {
  const Results({super.key});

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  final _supabaseService = SupabaseService();

  int _bucketHours = 3;
  String _textType = AppConstants.textTypeRaw; // TR: 'raw' | 'character_corrected' | 'meaning_corrected' | EN: 'raw' | 'character_corrected' | 'meaning_corrected' | RU: 'raw' | 'character_corrected' | 'meaning_corrected'

  bool _loading = true;                          
  List<Map<String, dynamic>> all = [];
  late final PageController _page;
  int _pageIndex = 0;

  List<bucket_card.Bucket> _buckets = const [];

  @override
  void initState() {
    super.initState();
    _page = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_page.hasClients) _page.jumpToPage(0);
    });

    _load();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // TR: Mevcut kullanıcıyı al | EN: Get current user | RU: Получить текущего пользователя
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // TR: Kullanıcıya özel sonuçları metin türüne göre al | EN: Get user-specific results by text type | RU: Получить результаты пользователя по типу текста
    final list = await _supabaseService.getUserResultsByType(user.id, _textType);

    list.sort((a, b) {
      final ad = DateTime.tryParse('${a['created_at']}') ?? DateTime(1970);
      final bd = DateTime.tryParse('${b['created_at']}') ?? DateTime(1970);
      return bd.compareTo(ad);
    });

    final grouped = _groupIntoBuckets(list, _bucketHours);

    if (!mounted) return;
    setState(() {
      all = list;
      _buckets = grouped;
      _pageIndex = 0;
      _loading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_page.hasClients && _buckets.isNotEmpty) {
        _page.jumpToPage(0);
      }
    });
  }

  DateTime _bucketStart(DateTime dt, int hours) {
    final h = (dt.hour ~/ hours) * hours;
    return DateTime(dt.year, dt.month, dt.day, h);
  }

  String _bucketLabel(DateTime start, int hours) {
    final end = start.add(Duration(hours: hours));
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${start.year}-${two(start.month)}-${two(start.day)} ${two(start.hour)}:00';
    final e = '${two(end.hour)}:00';
    return '$s – $e';
  }

  List<bucket_card.Bucket> _groupIntoBuckets(List<Map<String, dynamic>> rows, int hours) {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final dt = DateTime.tryParse('${r['created_at']}');
      if (dt == null) continue;
      final key = _bucketStart(dt, hours);
      (map[key] ??= []).add(r);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final k in keys)
        bucket_card.Bucket(
          start: k,
          label: _bucketLabel(k, hours),
          items: (map[k]!
            ..sort((a, b) {
              final ad = DateTime.tryParse('${a['created_at']}') ?? DateTime(1970);
              final bd = DateTime.tryParse('${b['created_at']}') ?? DateTime(1970);
              return bd.compareTo(ad);
            })),
        )
    ];
  }

  void _next() {
    if (_page.hasClients && _pageIndex < (_buckets.length - 1)) {
      _page.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  void _prev() {
    if (_page.hasClients && _pageIndex > 0) {
      _page.previousPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Pencere (saat)',
            initialValue: _bucketHours,
            onSelected: (v) async {
              setState(() => _bucketHours = v);
              await _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('1 saat')),
              PopupMenuItem(value: 3, child: Text('3 saat')),
              PopupMenuItem(value: 6, child: Text('6 saat')),
              PopupMenuItem(value: 24, child: Text('24 saat')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 6),
                Text('${_bucketHours}h'),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Metin türü',
            initialValue: _textType,
            onSelected: (v) {
              setState(() => _textType = v);
              _load(); // TR: Metin türü değişince veriyi yeniden yükle | EN: Reload data when text type changes | RU: Перезагрузи данные при смене типа текста
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: AppConstants.textTypeRaw, child: Text(AppStrings.rawText)),
              PopupMenuItem(value: AppConstants.textTypeCharacterCorrected, child: Text(AppStrings.characterCorrected)),
              PopupMenuItem(value: AppConstants.textTypeMeaningCorrected, child: Text(AppStrings.meaningCorrected)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                const Icon(Icons.article_outlined),
                const SizedBox(width: 6),
                Text(_textType == AppConstants.textTypeRaw ? AppStrings.rawText : 
                     (_textType == AppConstants.textTypeCharacterCorrected ? AppStrings.characterCorrected : AppStrings.meaningCorrected)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
          ),
          IconButton(onPressed: _load, tooltip: 'Yenile', icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/ocr/results'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_buckets.isEmpty
              ? const Center(child: Text('Kayıt yok'))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      color: cs.surfaceContainerHighest,
                      child: Text(
                        _buckets[_pageIndex].label,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _page,
                        onPageChanged: (i) => setState(() => _pageIndex = i),
                        itemCount: _buckets.length,
                        itemBuilder: (_, i) {
                          final b = _buckets[i];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                            child: bucket_card.BucketCard(
                              key: ValueKey('${b.start}_$_textType'),
                              bucket: b,
                              textType: _textType,
                              onChangeTextType: (v) => setState(() => _textType = v),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )),
      floatingActionButton: _buckets.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pageIndex > 0)
                  FloatingActionButton.small(
                    heroTag: 'prev',
                    onPressed: _prev,
                    tooltip: 'Önceki dilim',
                    child: const Icon(Icons.arrow_back),
                  ),
                const SizedBox(width: 8),
                if (_pageIndex < _buckets.length - 1)
                  FloatingActionButton.extended(
                    heroTag: 'next',
                    onPressed: _next,
                    label: const Text('Sonraki'),
                    icon: const Icon(Icons.arrow_forward),
                  ),
              ],
            ),
    );
  }
}
