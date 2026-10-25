import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/expression_frame.dart';

/// 32 x 32 logical pixels, scaled using integer rectangles (no image assets).
class PixelFace extends StatefulWidget {
  final ExpressionFrame frame;
  const PixelFace({super.key, required this.frame});
  @override
  State<PixelFace> createState() => _PixelFaceState();
}

class _PixelFaceState extends State<PixelFace> {
  Timer? _timer;
  int _tick = 0;
  void _sync() {
    _timer?.cancel();
    if (!widget.frame.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context)) {
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() => _tick = (_tick + 1) % 16);
      });
    } else {
      _tick = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant PixelFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.reducedMotion != widget.frame.reducedMotion) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    image: true,
    excludeSemantics: true,
    label:
        '${widget.frame.name}: ${widget.frame.expression.title}. ${widget.frame.expression.description}',
    child: RepaintBoundary(
      child: CustomPaint(
        painter: PixelFacePainter(widget.frame, _tick),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class PixelFacePainter extends CustomPainter {
  final ExpressionFrame frame;
  final int tick;
  const PixelFacePainter(this.frame, [this.tick = 0]);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.src);
    final scale = math.max(
      1.0,
      (math.min(size.width, size.height) / 32).floorToDouble(),
    );
    canvas.save();
    canvas.translate(
      ((size.width - 32 * scale) / 2).floorToDouble(),
      ((size.height - 32 * scale) / 2).floorToDouble(),
    );
    canvas.scale(scale);
    const yellow = Color(0xFFFFD400), shadow = Color(0xFFF2AB00);
    const pink = Color(0xFFE43877), blue = Color(0xFF6AD9FF);
    final paint = Paint()..isAntiAlias = false;
    // In monochrome the background stays black, face white, marks black.
    void block(int x, int y, int w, int h, Color color) {
      paint.color = frame.monochrome && color != Colors.black
          ? Colors.white
          : color;
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
        paint,
      );
    }

    final e = frame.expression;
    final faceColor = e == PixelExpression.hot
        ? const Color(0xFFFFAF3D)
        : yellow;
    for (var y = 3; y < 30; y++) {
      for (var x = 3; x < 30; x++) {
        if (math.pow(x - 16, 2) + math.pow(y - 16, 2) <= 13.5 * 13.5) {
          block(x, y, 1, 1, x > 25 ? shadow : faceColor);
        }
      }
    }
    final blink = tick >= 14 && e != PixelExpression.sleepy;
    if (blink || e == PixelExpression.sleepy || e == PixelExpression.calm) {
      block(9, 12, 5, 2, Colors.black);
      block(19, 12, 5, 2, Colors.black);
    } else if (e == PixelExpression.loved) {
      for (final x in [9, 19]) {
        block(x, 12, 1, 2, Colors.black);
        block(x + 1, 11, 3, 1, Colors.black);
        block(x + 4, 12, 1, 2, Colors.black);
      }
    } else if (e == PixelExpression.thirsty ||
        e == PixelExpression.lonely ||
        e == PixelExpression.hot) {
      block(9, 13, 5, 2, Colors.black);
      block(19, 13, 5, 2, Colors.black);
      block(9, 11, 2, 1, Colors.black);
      block(22, 11, 2, 1, Colors.black);
    } else if (e == PixelExpression.curious) {
      block(9, 10, 5, 6, Colors.black);
      block(19, 10, 5, 6, Colors.black);
      block(10, 10, 1, 2, Colors.white);
      block(20, 10, 1, 2, Colors.white);
    } else {
      block(9, 12, 2, 2, Colors.black);
      block(11, 11, 2, 2, Colors.black);
      block(13, 12, 2, 2, Colors.black);
      block(19, 12, 5, 2, Colors.black);
    }
    switch (e) {
      case PixelExpression.happy:
      case PixelExpression.loved:
        block(9, 18, 15, 3, Colors.black);
        block(10, 21, 13, 2, Colors.black);
        block(12, 23, 9, 2, Colors.black);
        block(13, 21, 7, 4, pink);
        block(14, 25, 5, 1, pink);
      case PixelExpression.calm:
        block(10, 19, 13, 2, Colors.black);
      case PixelExpression.sleepy:
      case PixelExpression.curious:
        block(14, 19, 5, 5, Colors.black);
        block(15, 20, 3, 3, yellow);
      case PixelExpression.thirsty:
        block(12, 21, 4, 2, Colors.black);
        block(16, 22, 5, 2, Colors.black);
      case PixelExpression.hot:
        block(10, 21, 3, 2, Colors.black);
        block(13, 20, 3, 2, Colors.black);
        block(16, 21, 3, 2, Colors.black);
        block(19, 20, 3, 2, Colors.black);
      case PixelExpression.lonely:
        block(12, 22, 2, 2, Colors.black);
        block(14, 21, 5, 2, Colors.black);
        block(19, 22, 2, 2, Colors.black);
    }
    if (e == PixelExpression.thirsty ||
        e == PixelExpression.hot ||
        e == PixelExpression.lonely) {
      final x = e == PixelExpression.hot
          ? 26
          : e == PixelExpression.lonely
          ? 8
          : 23;
      final y = (e == PixelExpression.hot ? 8 : 16) + (tick ~/ 4 % 2);
      block(x, y, 1, 2, blue);
      block(x - 1, y + 2, 3, 3, blue);
    }
    if (e == PixelExpression.loved) {
      for (final origin in [const Offset(2, 4), const Offset(26, 3)]) {
        final x = origin.dx.toInt(), y = origin.dy.toInt() + (tick ~/ 4 % 2);
        block(x, y, 2, 1, pink);
        block(x + 3, y, 2, 1, pink);
        block(x, y + 1, 5, 1, pink);
        block(x + 1, y + 2, 3, 1, pink);
        block(x + 2, y + 3, 1, 1, pink);
      }
    }
    if (e == PixelExpression.sleepy) {
      final x = 25, y = 3 + (tick ~/ 4 % 2);
      block(x, y, 5, 1, blue);
      block(x + 3, y + 1, 1, 1, blue);
      block(x + 2, y + 2, 1, 1, blue);
      block(x + 1, y + 3, 1, 1, blue);
      block(x, y + 4, 5, 1, blue);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PixelFacePainter old) =>
      old.frame != frame || old.tick != tick;
}
