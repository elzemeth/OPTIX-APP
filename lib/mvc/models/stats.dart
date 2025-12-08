class Stats {
  final int totalWords7d;
  final int totalRecords7d;
  final double avgWordsPerRecord;
  final int maxWordsSingle;
  final int todayWords;
  final int activeDays7d;
  final DateTime lastUpdated;

  Stats({
    required this.totalWords7d,
    required this.totalRecords7d,
    required this.avgWordsPerRecord,
    required this.maxWordsSingle,
    required this.todayWords,
    required this.activeDays7d,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'totalWords7d': totalWords7d,
        'totalRecords7d': totalRecords7d,
        'avgWordsPerRecord': avgWordsPerRecord,
        'maxWordsSingle': maxWordsSingle,
        'todayWords': todayWords,
        'activeDays7d': activeDays7d,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Stats.fromJson(Map<String, dynamic> m) => Stats(
        totalWords7d: (m['totalWords7d'] as num).toInt(),
        totalRecords7d: (m['totalRecords7d'] as num).toInt(),
        avgWordsPerRecord: (m['avgWordsPerRecord'] as num).toDouble(),
        maxWordsSingle: (m['maxWordsSingle'] as num).toInt(),
        todayWords: (m['todayWords'] as num).toInt(),
        activeDays7d: (m['activeDays7d'] as num).toInt(),
        lastUpdated: DateTime.parse(m['lastUpdated'] as String),
      );
}
