import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/plant_data.dart';
import '../models/sensor_gauge.dart';
import 'design.dart';

const _zoneColors = [
  Color(0xFF80ABCD),
  Color(0xFFB9D8E7),
  Color(0xFF9FC987),
  Color(0xFFF2CF78),
  Color(0xFFE69A86),
];
const _zoneFills = [Color(0xFFE5EFF7), sky, mint, sun, coral];
const _sensorIcons = [
  Icons.water_drop_outlined,
  Icons.wb_sunny_outlined,
  Icons.thermostat_rounded,
  Icons.air_rounded,
  Icons.science_outlined,
];

Widget _centerCondition(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: child,
  ),
);

// Keep individual cards as individual scroll items on Home. One oversized lazy
// list child can produce jumps while Flutter estimates the remaining extent.
List<Widget> plantConditionSections({
  required PlantData data,
  required VoidCallback openLab,
}) => [
  _centerCondition(
    Builder(
      builder: (context) => Column(
        children: [
          Text(
            'Plant conditions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'A little balance for your ${data.profile.name}.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Tag('Simulated readings', color: sky),
        ],
      ),
    ),
  ),
  for (final gauge in sensorGauges(data))
    _centerCondition(
      SensorStatusCard(key: ValueKey('gauge-${gauge.id}'), gauge: gauge),
    ),
  _centerCondition(
    Column(
      children: [
        const Text(
          'Five care zones, not a linear scale. The green band is the species’ ideal range. All ranges are illustrative prototype rules.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: openLab,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Change readings in Lab'),
        ),
      ],
    ),
  ),
];

class PlantConditions extends StatelessWidget {
  final PlantData data;
  final VoidCallback openLab;
  const PlantConditions({super.key, required this.data, required this.openLab});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final section in plantConditionSections(
        data: data,
        openLab: openLab,
      )) ...[section, const SizedBox(height: 14)],
    ],
  );
}

class SensorStatusCard extends StatelessWidget {
  final SensorGauge gauge;
  const SensorStatusCard({super.key, required this.gauge});
  Future<void> _details(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${gauge.label} ranges'),
      content: SingleChildScrollView(
        child: Text(
          '${gauge.rangeDetails}\n\nThe ideal range uses the selected plant profile. The two outside regions are each split in half for the five-zone preview; these are not validated severity thresholds.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => SoftCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _zoneFills[gauge.zone.index],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _sensorIcons[[
                  'moisture',
                  'light',
                  'temperature',
                  'humidity',
                  'ph',
                ].indexOf(gauge.id)],
                color: ink,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gauge.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    gauge.reading,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '${gauge.label} range details',
              onPressed: () => _details(context),
              icon: const Icon(Icons.info_outline_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tag(gauge.zone.label, color: _zoneFills[gauge.zone.index]),
            Text(
              'Ideal ${gauge.target}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF52664F)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          container: true,
          label: gauge.accessibleDescription,
          excludeSemantics: true,
          child: Column(
            children: [
              SizedBox(
                height: 42,
                width: double.infinity,
                child: CustomPaint(
                  painter: _StatusTrack(gauge.pointerFraction),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final zone in CareZone.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Text(
                          switch (zone) {
                            CareZone.veryLow => 'Very\nlow',
                            CareZone.veryHigh => 'Very\nhigh',
                            _ => zone.label,
                          },
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: zone == gauge.zone
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: zone == gauge.zone
                                ? ink
                                : const Color(0xFF536158),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusTrack extends CustomPainter {
  final double position;
  const _StatusTrack(this.position);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 23, size.width, 14),
      const Radius.circular(7),
    );
    canvas.save();
    canvas.clipRRect(bar);
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * i / 5, 23, size.width / 5 + .5, 14),
        paint..color = _zoneColors[i],
      );
    }
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(size.width * i / 5, 23),
        Offset(size.width * i / 5, 37),
        paint
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
    final x = (position * size.width)
        .clamp(5.0, math.max(5.0, size.width - 5))
        .toDouble();
    canvas.drawLine(
      Offset(x, 16),
      Offset(x, 39),
      paint
        ..color = Colors.white
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      Offset(x, 16),
      Offset(x, 39),
      paint
        ..color = ink
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x - 6, 11)
        ..lineTo(x + 6, 11)
        ..lineTo(x, 20)
        ..close(),
      paint
        ..color = ink
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(Offset(x, 7), 3, paint..color = ink);
  }

  @override
  bool shouldRepaint(_StatusTrack oldDelegate) =>
      oldDelegate.position != position;
}
