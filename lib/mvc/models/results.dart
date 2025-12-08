class Result {
  final int id;
  final String file;
  final String? ts;
  final int? textIndex;
  final String? textType;
  final String text;
  final double confidence;
  final Map<String, dynamic>? box;
  final String? createdBy;
  final DateTime createdAt;

  Result({
    required this.id,
    required this.file,
    required this.text,
    required this.confidence,
    required this.createdAt,
    this.ts,
    this.textIndex,
    this.textType,
    this.box,
    this.createdBy,
  });

  factory Result.fromJson(Map<String, dynamic> j) {
    return Result(
      id: j['id'] as int,
      file: j['file'] as String,
      ts: j['ts'] as String?,
      textIndex: j['text_index'] as int?,
      textType: j['text_type'] as String?,
      text: j['text'] as String,
      confidence: double.tryParse('${j['confidence']}') ?? 0.0,
      box: j['box'] as Map<String, dynamic>?,
      createdBy: j['created_by']?.toString(),
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

