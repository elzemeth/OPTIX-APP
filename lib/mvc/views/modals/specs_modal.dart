import 'package:flutter/material.dart';

class GlassesSpecsModal extends StatelessWidget {
  final GlassesSpecs specs;

  const GlassesSpecsModal({super.key, required this.specs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Gözlük Donanım Özellikleri'),
          leading: IconButton(
            tooltip: 'Kapat',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _kv('Model', specs.model),
            _kv('Kart / SoC', specs.board),
            _kv('Kamera', specs.camera),
            _kv('Lens', specs.lens),
            _kv('Çözünürlük', specs.resolution),
            _kv('Bağlantı', specs.connectivity),
            _kv('Batarya', specs.battery),
            _kv('Sensör', specs.sensor),
            _kv('Piksel Boyutu', specs.pixelSize),
            _kv('Optik Boyutu', specs.opticSize),
            _kv('Diğer', specs.other),
          ].whereType<Widget>().toList(),
        ),
      ),
    );
  }

  Widget? _kv(String k, String? v) {
    if (v == null || v.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class GlassesSpecs {
  final String? model, board, camera, lens, resolution, connectivity, battery, sensor, pixelSize, opticSize, other;
  const GlassesSpecs({
    this.model, this.board, this.camera, this.lens, this.resolution,
    this.connectivity, this.battery, this.sensor, this.pixelSize, this.opticSize, this.other,
  });
}
