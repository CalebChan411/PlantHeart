import 'package:flutter/material.dart';
import '../models/sensor_gauge.dart';
import 'design.dart';
import 'sensor_status.dart';

/// Three readable bands for the at-a-glance Home view. Full five-zone rules and
/// exact species ranges remain available in the details dialog.
class CompactSensorStatus extends StatelessWidget {
  final SensorGauge gauge;
  const CompactSensorStatus({super.key, required this.gauge});
  int get band => gauge.zone.index < 2
      ? 0
      : gauge.zone == CareZone.ideal
      ? 1
      : 2;
  double get pointer {
    final left = [gauge.minimum, gauge.idealMinimum, gauge.idealMaximum][band];
    final right = [gauge.idealMinimum, gauge.idealMaximum, gauge.maximum][band];
    return (band + ((gauge.value - left) / (right - left)).clamp(0.0, 1.0)) / 3;
  }

  static const colors = [
    Color(0xFFF2B0A8),
    Color(0xFFA2CE8F),
    Color(0xFFF7D987),
  ];
  static const fills = [coral, mint, sun];
  static const labels = ['Low', 'Ideal', 'High'];
  static const names = {
    'moisture': 'Moisture',
    'light': 'Light',
    'temperature': 'Temp.',
    'humidity': 'Humidity',
    'ph': 'Soil pH',
  };
  static const icons = {
    'moisture': Icons.water_drop_rounded,
    'light': Icons.wb_sunny_rounded,
    'temperature': Icons.thermostat_rounded,
    'humidity': Icons.air_rounded,
    'ph': Icons.science_outlined,
  };
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: gauge.accessibleDescription,
    child: Material(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(gauge.label),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SensorStatusCard(gauge: gauge),
                  const SizedBox(height: 16),
                  Text(
                    '${gauge.rangeDetails}\n\nHome uses three equal care bands, not a linear number line. Ideal limits come from the active plant species. Five-zone subdivisions are illustrative, not scientific severity thresholds.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: fills[band],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icons[gauge.id] ?? Icons.sensors,
                    size: 18,
                    color: leaf,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        names[gauge.id] ?? gauge.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        gauge.reading,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF536158),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 23,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _CompactTrack(pointer, colors[band]),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Expanded(
                                child: Text(
                                  labels[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.1,
                                    fontWeight: i == band
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: i == band
                                        ? ink
                                        : const Color(0xFF6A746E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CompactTrack extends CustomPainter {
  final double position;
  final Color accent;
  const _CompactTrack(this.position, this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 3, size.width, 16),
        const Radius.circular(9),
      ),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * i / 3, 3, size.width / 3 + .5, 16),
        p..color = CompactSensorStatus.colors[i],
      );
    }
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 3),
        Offset(size.width * i / 3, 19),
        p
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();
    final x = (position * size.width).clamp(8.0, size.width - 8).toDouble();
    canvas.drawCircle(Offset(x, 11), 7, p..color = const Color(0x33243C32));
    canvas.drawCircle(Offset(x, 10), 6.5, p..color = Colors.white);
    canvas.drawCircle(Offset(x, 10), 3.8, p..color = accent);
  }

  @override
  bool shouldRepaint(_CompactTrack old) =>
      old.position != position || old.accent != accent;
}
