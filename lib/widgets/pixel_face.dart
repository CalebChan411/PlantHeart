import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/expression_frame.dart';

/// Features only: black background, white pixel eyes, eyebrows and mouth.
/// No head silhouette, avatar ring, colored face fill or downloaded assets.
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
      _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        if (mounted) setState(() => _tick = (_tick + 1) % 120);
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
    if (oldWidget.frame.replyId != widget.frame.replyId) _tick = 0;
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
        '${widget.frame.name}: ${widget.frame.expression.title}. ${widget.frame.expression.description}'
        '${widget.frame.replyingAt(DateTime.now()) ? ' Reply animation. No audio is generated.' : ''}',
    child: RepaintBoundary(
      child: CustomPaint(
        painter: PixelFacePainter(
          widget.frame,
          widget.frame.reducedMotion || MediaQuery.disableAnimationsOf(context)
              ? 0
              : _tick,
        ),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class PixelFacePainter extends CustomPainter {
  static const columns = 32, rows = 24;
  final ExpressionFrame frame;
  final int tick;
  const PixelFacePainter(this.frame, [this.tick = 0]);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // CustomPaint does not clip by default. Keep the black display background
    // inside its viewport rather than painting over the surrounding tool UI.
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(Colors.black, BlendMode.src);
    final scale = math.max(
      1.0,
      math.min(size.width / columns, size.height / rows).floorToDouble(),
    );
    canvas.translate(
      ((size.width - columns * scale) / 2).floorToDouble(),
      ((size.height - rows * scale) / 2).floorToDouble(),
    );
    canvas.scale(scale);
    final paint = Paint()..isAntiAlias = false;
    void block(int x, int y, int w, int h, [Color color = Colors.white]) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble()),
        paint..color = color,
      );
    }

    final e = frame.expression;
    final blink = tick % 36 >= 34 && e != PixelExpression.sleepy;
    final gaze = frame.reducedMotion ? 0 : [0, 1, 0, -1][tick ~/ 12 % 4];
    if (blink || e == PixelExpression.sleepy || e == PixelExpression.calm) {
      block(6 + gaze, 8, 6, 1);
      block(20 + gaze, 8, 6, 1);
    } else if (e == PixelExpression.happy || e == PixelExpression.loved) {
      for (final x in [6 + gaze, 20 + gaze]) {
        block(x, 8, 1, 2);
        block(x + 1, 7, 4, 1);
        block(x + 5, 8, 1, 2);
      }
      if (e == PixelExpression.happy) {
        block(20 + gaze, 7, 6, 3, Colors.black);
        block(20 + gaze, 8, 6, 1);
      }
    } else if (e == PixelExpression.curious) {
      for (final x in [6 + gaze, 20 + gaze]) {
        block(x, 5, 6, 6);
        block(x + 2, 6, 2, 3, Colors.black);
      }
      block(6, 2, 5, 1);
      block(21, 2, 5, 1);
    } else if (e == PixelExpression.hot) {
      for (final x in [6, 20]) {
        block(x, 6, 2, 1);
        block(x + 2, 7, 2, 1);
        block(x + 4, 8, 2, 1);
        block(x, 8, 2, 1);
        block(x + 4, 6, 2, 1);
      }
      block(6, 3, 4, 1);
      block(22, 3, 4, 1);
    } else {
      block(6 + gaze, 9, 6, 1);
      block(20 + gaze, 9, 6, 1);
      block(6, 4, 2, 1);
      block(8, 5, 4, 1);
      block(20, 5, 4, 1);
      block(24, 4, 2, 1);
    }
    final replying = frame.replyingAt(DateTime.now()) && !frame.reducedMotion;
    if (replying) {
      // A deterministic visual speech cycle, not audio/phoneme synchronization.
      switch (tick % 6) {
        case 0:
          block(11, 17, 10, 1);
        case 1:
          block(13, 16, 6, 3);
          block(14, 17, 4, 1, Colors.black);
        case 2:
          block(10, 15, 12, 5);
          block(12, 16, 8, 2, Colors.black);
        case 3:
          block(12, 16, 8, 4);
          block(13, 17, 6, 1, Colors.black);
        case 4:
          block(13, 15, 6, 6);
          block(14, 16, 4, 3, Colors.black);
        case 5:
          block(11, 16, 10, 3);
          block(12, 17, 8, 1, Colors.black);
      }
    } else {
      switch (e) {
        case PixelExpression.happy:
        case PixelExpression.loved:
          block(9, 15, 2, 3);
          block(11, 18, 10, 2);
          block(21, 15, 2, 3);
          if (e == PixelExpression.loved) block(13, 20, 6, 1);
        case PixelExpression.calm:
          block(11, 17, 10, 1);
        case PixelExpression.sleepy:
        case PixelExpression.curious:
          block(13, 15, 6, 5);
          block(14, 16, 4, 3, Colors.black);
        case PixelExpression.thirsty:
          block(11, 17, 5, 1);
          block(16, 18, 5, 1);
        case PixelExpression.hot:
          block(10, 16, 3, 1);
          block(13, 17, 3, 1);
          block(16, 16, 3, 1);
          block(19, 17, 3, 1);
        case PixelExpression.lonely:
          block(11, 18, 2, 2);
          block(13, 17, 6, 1);
          block(19, 18, 2, 2);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PixelFacePainter old) =>
      old.frame != frame || old.tick != tick;
}
