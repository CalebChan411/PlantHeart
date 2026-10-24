import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'design.dart';

/// Original vector character: no remote images or animation dependencies.
class Milo extends StatefulWidget {
  final String mood, name;
  final bool reducedMotion;
  final double height;
  const Milo({
    super.key,
    this.mood = 'Thriving',
    this.name = 'Milo',
    this.reducedMotion = false,
    this.height = 260,
  });
  @override
  State<Milo> createState() => _MiloState();
}

class _MiloState extends State<Milo> with SingleTickerProviderStateMixin {
  late final AnimationController sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  void syncMotion() {
    if (widget.reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      sway.stop();
      sway.value = .5;
    } else if (!sway.isAnimating) {
      sway.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncMotion();
  }

  @override
  void didUpdateWidget(covariant Milo oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncMotion();
  }

  @override
  void dispose() {
    sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${widget.name}, a smiling potted plant. Simulated mood: ${widget.mood}.',
    image: true,
    child: SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: sway,
        builder: (context, child) => CustomPaint(
          painter: _MiloPainter(widget.mood, (sway.value - .5) * .04),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _MiloPainter extends CustomPainter {
  final String mood;
  final double sway;
  _MiloPainter(this.mood, this.sway);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = math.min(size.width / 340, size.height / 280);
    canvas.translate(
      (size.width - 340 * scale) / 2,
      (size.height - 280 * scale) / 2,
    );
    canvas.scale(scale);
    final p = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(51, 243, 238, 23),
      p..color = const Color(0xFFD7E6C6),
    );
    canvas.drawCircle(
      const Offset(170, 135),
      117,
      p..color = const Color(0xFFE4F0D5),
    );
    canvas.drawCircle(
      const Offset(273, 45),
      21,
      p..color = const Color(0xFFFFDC7F),
    );
    for (final dot in [
      const Offset(55, 93),
      const Offset(287, 157),
      const Offset(86, 217),
    ]) {
      canvas.drawCircle(dot, 4, p..color = const Color(0xFFA7C994));
    }
    // The leaves sway independently of the grounded pot.
    canvas.save();
    canvas.translate(170, 191);
    canvas.rotate(sway);
    canvas.translate(-170, -191);
    final stem = Paint()
      ..color = const Color(0xFF388049)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(170, 194)
        ..quadraticBezierTo(153, 139, 175, 72),
      stem,
    );
    void leafShape(Offset root, Offset tip, Color color, double side) {
      final dx = tip.dx - root.dx, dy = tip.dy - root.dy;
      final path = Path()
        ..moveTo(root.dx, root.dy)
        ..cubicTo(
          root.dx + dx * .05 - side * 29,
          root.dy + dy * .65 - 25,
          tip.dx - side * 28,
          tip.dy - 25,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          tip.dx + side * 24,
          tip.dy + 36,
          root.dx + dx * .8 + side * 18,
          root.dy + 4,
          root.dx,
          root.dy,
        );
      canvas.drawPath(
        path,
        p
          ..style = PaintingStyle.fill
          ..color = color,
      );
      canvas.drawPath(
        Path()
          ..moveTo(root.dx, root.dy)
          ..quadraticBezierTo(
            (root.dx + tip.dx) / 2,
            (root.dy + tip.dy) / 2 - 5,
            tip.dx,
            tip.dy,
          ),
        Paint()
          ..color = const Color(0x555C9E47)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    leafShape(
      const Offset(165, 148),
      const Offset(91, 103),
      const Color(0xFF72B950),
      -1,
    );
    leafShape(
      const Offset(166, 126),
      const Offset(245, 80),
      const Color(0xFF60AD49),
      1,
    );
    leafShape(
      const Offset(169, 99),
      const Offset(131, 40),
      const Color(0xFF8ACB60),
      -1,
    );
    leafShape(
      const Offset(171, 85),
      const Offset(200, 28),
      const Color(0xFF4F9B43),
      1,
    );
    canvas.restore();
    final pot = Path()
      ..moveTo(111, 182)
      ..lineTo(229, 182)
      ..lineTo(217, 245)
      ..quadraticBezierTo(169, 268, 123, 245)
      ..close();
    canvas.drawPath(pot, p..color = const Color(0xFFE6AF83));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(104, 173, 132, 24),
        const Radius.circular(9),
      ),
      p..color = const Color(0xFFF4C69F),
    );
    final face = Paint()
      ..color = ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final sleepy = mood == 'Sleepy';
    for (final x in [148.0, 192.0]) {
      if (sleepy) {
        canvas.drawLine(Offset(x - 5, 217), Offset(x + 5, 217), face);
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 215), width: 7, height: 10),
          Paint()..color = ink,
        );
      }
    }
    canvas.drawCircle(
      const Offset(135, 225),
      6,
      p..color = const Color(0xFFDE9380),
    );
    canvas.drawCircle(
      const Offset(205, 225),
      6,
      p..color = const Color(0xFFDE9380),
    );
    final mouth = Path()
      ..moveTo(158, mood == 'Thirsty' ? 237 : 228)
      ..quadraticBezierTo(
        170,
        mood == 'Thirsty' ? 224 : 241,
        182,
        mood == 'Thirsty' ? 237 : 228,
      );
    canvas.drawPath(mouth, face);
    if (mood == 'Thirsty') {
      canvas.drawPath(
        Path()
          ..moveTo(243, 119)
          ..quadraticBezierTo(225, 144, 242, 145)
          ..quadraticBezierTo(259, 144, 243, 119),
        p..color = const Color(0xFF8CC6DD),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MiloPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.sway != sway;
}
