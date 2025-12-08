import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';
import '../../models/stats.dart';
import '../modals/specs_modal.dart';
import '../widgets/spritesheet_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sb = Supabase.instance.client;

  bool _loading = false;
  String? error;

  Stats? _stats;
  static const _cacheKey = 'stats_cache_v1';

  @override
  void initState() {
    super.initState();
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final sp = await SharedPreferences.getInstance();
    final j = sp.getString(_cacheKey);
    if (j != null) {
      try {
        setState(() => _stats = Stats.fromJson(jsonDecode(j)));
      } catch (_) {}
    }
  }

  Future<void> _saveToCache(Stats s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_cacheKey, jsonEncode(s.toJson()));
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      error = null;
    });

    try {
      final now = DateTime.now();
      final since = now.subtract(const Duration(days: 7)).toIso8601String();

      final res = await _sb.from('results').select().gte('created_at', since);

      final rows = List<Map<String, dynamic>>.from(res);
      final stats = _computeStats(rows);

      if (!mounted) return;
      setState(() => _stats = stats);
      await _saveToCache(stats);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İstatistikler alınamadı: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Stats _computeStats(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    int totalWords = 0;
    int totalRecords = 0;
    int maxWords = 0;
    int todayWords = 0;
    final activeDays = <String>{};

    for (final r in rows) {
      final ts = _parseTs(r);
      if (ts == null || ts.isBefore(start)) continue;

      final w = _countWords(r);
      totalWords += w;
      totalRecords += 1;
      if (w > maxWords) maxWords = w;

      if (_isSameDay(ts, now)) todayWords += w;
      activeDays.add(_dayKey(ts));
    }

    final avg = totalRecords == 0 ? 0.0 : totalWords / totalRecords;

    return Stats(
      totalWords7d: totalWords,
      totalRecords7d: totalRecords,
      avgWordsPerRecord: avg,
      maxWordsSingle: maxWords,
      todayWords: todayWords,
      activeDays7d: activeDays.length,
      lastUpdated: DateTime.now(),
    );
  }

  DateTime? _parseTs(Map<String, dynamic> r) {
    for (final k in const ['created_at', 'inserted_at', 'ts', 'timestamp']) {
      final v = r[k];
      if (v is String) {
        try {
          return DateTime.parse(v).toLocal();
        } catch (_) {}
      }
      if (v is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(v).toLocal();
        } catch (_) {}
      }
    }
    return null;
  }

  int _countWords(Map<String, dynamic> r) {
    final t = r['texts'];
    if (t is List) {
      return t
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .length;
    }
    final s = (r['full_text'] ?? r['text']) as String?;
    if (s != null) {
      return RegExp(r'\S+').allMatches(s).length;
    }
    for (final key in const ['payload', 'jsonl', 'data', 'raw']) {
      final v = r[key];
      if (v is String && v.contains('[') && v.contains('texts')) {
        try {
          final m = jsonDecode(v);
          if (m is Map && m['texts'] is List) {
            return (m['texts'] as List)
                .whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .length;
          }
        } catch (_) {}
      }
    }
    return 0;
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtInt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    int cnt = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      b.write(s[i]);
      cnt++;
      if (cnt == 3 && i != 0) {
        b.write('.');
        cnt = 0;
      }
    }
    return b.toString().split('').reversed.join();
  }

  String _prettyTime(DateTime d) {
    final t = d.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openGlassesModal() async {
    final specs = GlassesSpecs(
      model: 'OPTIX Prototype',
      board: 'Raspberry Pi Zero 2 W',
      camera: 'Sony IMX477 (12MP)',
      lens: '6mm / F1.8',
      resolution: '4608×2592',
      connectivity: 'Wi-Fi, BLE',
      battery: '3.7V Li-Po, korumalı',
      sensor: 'MPU-6050 (6-axis IMU)',
      pixelSize: '1.55µm',
      opticSize: '1/2.3"',
      other: 'OCR: PaddleOCR | Streaming: FFmpeg | Watchdog',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.96,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: GlassesSpecsModal(specs: specs),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          if (_stats?.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Son: ${_prettyTime(_stats!.lastUpdated)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          const SizedBox(width: 4),
          _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Yenile',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/home'),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Cache layout calculations to avoid recalculation
            final totalH = constraints.maxHeight;
            final totalW = constraints.maxWidth;

            final cols = totalW >= 1000 ? 3 : 2;
            final rows = (6 / cols).ceil();

            const crossSpacing = 12.0;
            const mainSpacing = 12.0;
            const middleGap = 16.0;

            // Optimize hero fraction calculation
            final heroFrac = totalH < 600 ? 0.28 : (totalW >= 1200 ? 0.40 : 0.33);
            final heroH = totalH * heroFrac;
            final gridH = totalH - heroH - middleGap;

            final usableW = totalW - (cols - 1) * crossSpacing;
            final cellW = usableW / cols;
            final cellH = (gridH - (rows - 1) * mainSpacing) / rows;
            final aspect = cellW / cellH;

            // Pre-calculate values to avoid recalculation in itemBuilder
            final values = _currentValues(cs, _stats);

            return Column(
              children: [
                SizedBox(height: heroH, child: _buildGlassesHeroCard()),
                const SizedBox(height: middleGap),
                SizedBox(
                  height: gridH,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: crossSpacing,
                      mainAxisSpacing: mainSpacing,
                      childAspectRatio: aspect,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, i) => values[i],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassesHeroCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _openGlassesModal,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SpriteSheetPlayer(
              asset: 'assets/spritesheet.png',
              columns: 12,
              rows: 10,
              frameCount: 120,
              fps: 30,
              autoPlay: true,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  Text(
                    'OPTIX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Gözlük Bilgileri İçin Tıklayın!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _currentValues(ColorScheme cs, Stats? s) {
    return [
      StatCard(
        key: const ValueKey('total_words'),
        title: 'Toplam Kelime',
        value: s == null ? '—' : _fmtInt(s.totalWords7d),
        icon: Icons.text_snippet_outlined,
        color: cs.secondary,
      ),
      StatCard(
        key: const ValueKey('total_records'),
        title: 'Toplam Görüntü',
        value: s == null ? '—' : _fmtInt(s.totalRecords7d),
        icon: Icons.image_outlined,
        color: cs.tertiary,
      ),
      StatCard(
        key: const ValueKey('avg_words'),
        title: 'Ortalama Kelime/Görüntü',
        value: s == null ? '—' : s.avgWordsPerRecord.toStringAsFixed(1),
        icon: Icons.analytics_outlined,
        color: cs.primary,
      ),
      StatCard(
        key: const ValueKey('max_words'),
        title: 'Tek Karede Maks. Kelime',
        value: s == null ? '—' : _fmtInt(s.maxWordsSingle),
        icon: Icons.trending_up_outlined,
        color: cs.secondaryContainer,
      ),
      StatCard(
        key: const ValueKey('today_words'),
        title: 'Bugünkü Kelime Sayısı',
        value: s == null ? '—' : _fmtInt(s.todayWords),
        icon: Icons.today_outlined,
        color: cs.tertiaryContainer,
      ),
      StatCard(
        key: const ValueKey('active_days'),
        title: 'Aktif Gün Sayısı',
        value: s == null ? '—' : _fmtInt(s.activeDays7d),
        icon: Icons.calendar_month_outlined,
        color: cs.primaryContainer,
      ),
    ];
  }
}
