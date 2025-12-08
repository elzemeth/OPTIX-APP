import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class SpriteSheetPlayer extends StatefulWidget {
  final String asset;
  final int columns, rows, frameCount;
  final int fps;
  final bool autoPlay;
  const SpriteSheetPlayer({
    super.key,
    required this.asset,
    required this.columns,
    required this.rows,
    required this.frameCount,
    this.fps = 30,
    this.autoPlay = true,
  });

  @override
  State<SpriteSheetPlayer> createState() => _SpriteSheetPlayerState();
}

class _SpriteSheetPlayerState extends State<SpriteSheetPlayer> {
  ui.Image? _sheet;
  int _frame = 0;
  Timer? _timer;
  double _dragAccum = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await rootBundle.load(widget.asset);
    final img = await decodeImageFromList(data.buffer.asUint8List());
    setState(() => _sheet = img);
    if (widget.autoPlay) {
      _timer = Timer.periodic(
        Duration(milliseconds: (1000 / widget.fps).round()),
        (_) => setState(() => _frame = (_frame + 1) % widget.frameCount),
      );
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_sheet == null) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        _dragAccum += d.delta.dx;
        const pxPerFrame = 8.0;
        while (_dragAccum.abs() >= pxPerFrame) {
          final dir = _dragAccum.isNegative ? 1 : -1;
          setState(() {
            _frame = (_frame + dir) % widget.frameCount;
            if (_frame < 0) _frame += widget.frameCount;
          });
          _dragAccum += dir * pxPerFrame;
        }
      },
      onTap: () {
        if (_timer == null) {
          _timer = Timer.periodic(
            Duration(milliseconds: (1000 / widget.fps).round()),
            (_) => setState(() => _frame = (_frame + 1) % widget.frameCount),
          );
        } else { _timer!.cancel(); _timer = null; }
      },
      child: CustomPaint(
        painter: _SpritePainter(
          sheet: _sheet!, frame: _frame,
          columns: widget.columns, rows: widget.rows,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image sheet; final int frame, columns, rows;
  _SpritePainter({required this.sheet, required this.frame, required this.columns, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final frameW = (sheet.width / columns).floor();
    final frameH = (sheet.height / rows).floor();
    final col = frame % columns;
    final row = frame ~/ columns;

    final src = Rect.fromLTWH(
      (col * frameW).toDouble(),
      (row * frameH).toDouble(),
      frameW.toDouble(),
      frameH.toDouble(),
    );

    final aspect = frameW / frameH;
    late Rect dst;
    if (size.width / size.height > aspect) {
      final w = size.height * aspect;
      dst = Rect.fromLTWH((size.width - w) / 2, 0, w, size.height);
    } else {
      final h = size.width / aspect;
      dst = Rect.fromLTWH(0, (size.height - h) / 2, size.width, h);
    }

    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(sheet, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.frame != frame || old.sheet != sheet;
}