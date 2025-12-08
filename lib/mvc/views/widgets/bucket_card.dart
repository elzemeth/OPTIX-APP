import 'package:flutter/material.dart';

class Bucket {
  final DateTime start;
  final String label;
  final List<Map<String, dynamic>> items;
  Bucket({required this.start, required this.label, required this.items});
} 


class BucketCard extends StatelessWidget {
  const BucketCard({ required super.key, required this.bucket, this.textType = 'raw', this.onChangeTextType});
  final Bucket bucket;
  final String textType; // which text_type to display
  final void Function(String)? onChangeTextType;

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.schedule, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    bucket.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      textType == 'raw' ? 'RAW' : (textType == 'character_corrected' ? 'CHARS' : 'MEANING'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ]),
                PopupMenuButton<String>(
                  tooltip: 'Metin türü',
                  onSelected: (v) => onChangeTextType?.call(v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'raw', child: Text('Raw')),
                    PopupMenuItem(value: 'character_corrected', child: Text('Character corrected')),
                    PopupMenuItem(value: 'meaning_corrected', child: Text('Meaning corrected')),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...bucket.items
                .where((r) => (r['text_type'] ?? '').toString() == textType)
                .where((r) => (r['text'] ?? '').toString().trim().isNotEmpty)
                .map((r) {
              final time = _fmtTime(r['created_at'] as String?);
              final file = (r['file'] ?? '').toString();
              final conf = (r['confidence']).toString();
              final ttype = (r['text_type'] ?? '?').toString().toUpperCase();
              final text = (r['text'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: cs.surfaceContainerHighest,
                          child: Text(ttype.isNotEmpty ? ttype[0] : '?'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'file: $file • conf: $conf',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
