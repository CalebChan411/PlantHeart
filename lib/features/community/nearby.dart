import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/plant_controller.dart';
import '../../services/neighbourhood.dart';
import '../../widgets/design.dart';

class NearbyPage extends StatefulWidget {
  final PlantController controller;
  const NearbyPage({super.key, required this.controller});
  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  String query = '', selected = 'fern';
  int radius = 1000;
  bool careOnly = false;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void open(NearbyPlant plant) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          NeighbourJournal(plant: plant, now: widget.controller.clock()),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final matches = searchNeighbours(
      query: query,
      radius: radius,
      careOnly: careOnly,
    );
    final active =
        matches.where((p) => p.id == selected).firstOrNull ??
        matches.firstOrNull;
    return PageBody(
      title: 'A greener\nneighbourhood.',
      subtitle: 'Find a little company for ${widget.controller.data.name}.',
      eyebrow: 'NEARBY PLANTHEARTS',
      children: [
        const Tag('Demo map · fictional places and distances', color: sky),
        TextField(
          controller: search,
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            labelText: 'Search nearby plants',
            hintText: 'Plant, owner, species or place',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear nearby search',
                    onPressed: () {
                      search.clear();
                      setState(() => query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final distance in [500, 1000, 2000])
              ChoiceChip(
                label: Text(
                  distance == 500 ? '500 m' : '${distance ~/ 1000} km',
                ),
                selected: radius == distance,
                onSelected: (_) => setState(() => radius = distance),
              ),
            FilterChip(
              label: const Text('Care checks'),
              selected: careOnly,
              onSelected: (v) => setState(() => careOnly = v),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1.3,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: NeighbourMapPainter()),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    top: 14,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Tag('Little Green District', color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Semantics(
                      label: 'Your PlantHeart, demo map centre',
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: ink,
                        size: 24,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: Text(
                      'Illustrated map · not GPS',
                      style: TextStyle(fontSize: 11, color: ink),
                    ),
                  ),
                  for (final plant in matches)
                    Builder(
                      builder: (_) {
                        // Schematic radial spacing keeps nearby demo pins separately tappable.
                        final angle = math.atan2(plant.north, plant.east);
                        final r =
                            math.sqrt(plant.distance / radius) *
                            math.min(box.maxWidth, box.maxHeight) *
                            .43;
                        return Positioned(
                          left: box.maxWidth / 2 + math.cos(angle) * r - 20,
                          top: box.maxHeight / 2 - math.sin(angle) * r - 20,
                          child: Semantics(
                            selected: active?.id == plant.id,
                            child: IconButton.filled(
                              tooltip:
                                  '${plant.name}, ${plant.distanceLabel}, ${plant.status}',
                              style: IconButton.styleFrom(
                                backgroundColor: active?.id == plant.id
                                    ? leaf
                                    : Colors.white,
                                foregroundColor: active?.id == plant.id
                                    ? Colors.white
                                    : leaf,
                                side: BorderSide(
                                  color: plant.comfortable
                                      ? leaf
                                      : const Color(0xFFC18A36),
                                  width: 2,
                                ),
                              ),
                              onPressed: () =>
                                  setState(() => selected = plant.id),
                              icon: const Icon(
                                Icons.local_florist_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '${matches.length} ${matches.length == 1 ? 'PlantHeart' : 'PlantHearts'} found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              'Within ${radius < 1000 ? '$radius m' : '${radius ~/ 1000} km'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        if (active != null)
          SoftCard(
            color: mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Tag(
                      active.status,
                      color: active.comfortable ? Colors.white : sun,
                    ),
                    Tag(active.distanceLabel, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${active.name} & ${active.owner}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${active.profile.name} · ${active.place}'),
                const SizedBox(height: 8),
                Text(active.logs.first.title),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => open(active),
                  icon: const Icon(Icons.auto_stories_outlined),
                  label: const Text('View shared journal'),
                ),
              ],
            ),
          ),
        if (matches.isEmpty)
          const SoftCard(
            child: Text(
              'No demo plants match yet. Try a wider radius or clear your search.',
            ),
          ),
        for (final plant in matches)
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.spa_outlined, color: leaf),
              title: Text(plant.name),
              subtitle: Text(
                '${plant.profile.name}\n${plant.status} · ${plant.distanceLabel}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => open(plant),
            ),
          ),
        const Text(
          'These five neighbours share sample journals and readings. No location permission, map service or real device discovery is used.',
        ),
      ],
    );
  }
}

class NeighbourJournal extends StatelessWidget {
  final NearbyPlant plant;
  final DateTime now;
  const NeighbourJournal({super.key, required this.plant, required this.now});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${plant.name}’s shared journal'),
      backgroundColor: cream,
    ),
    body: SafeArea(
      child: PageBody(
        title: '${plant.name} & ${plant.owner}',
        subtitle: '${plant.profile.name} · ${plant.place}',
        eyebrow: 'SHARED DEMO PROFILE',
        children: [
          Wrap(
            spacing: 8,
            children: [
              Tag(plant.status, color: plant.comfortable ? mint : sun),
              Tag(plant.distanceLabel, color: sky),
            ],
          ),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Shared plant status'),
                const SizedBox(height: 12),
                for (final row in [
                  ('Soil moisture', '${plant.reading.moisture.round()}%'),
                  ('Light', '${plant.reading.light.round()} lux'),
                  ('Temperature', '${plant.reading.temperature.round()}°C'),
                  ('Air humidity', '${plant.reading.humidity.round()}%'),
                  ('Soil pH', plant.reading.ph.toStringAsFixed(1)),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(row.$1)),
                        Text(
                          row.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Text(plant.care.first.reason),
              ],
            ),
          ),
          const SectionTitle('Shared journal'),
          for (final log in plant.logs)
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(log.text),
                  const SizedBox(height: 12),
                  Text(
                    '${dateLabel(now.subtract(Duration(days: log.daysAgo))).substring(0, 10)} · demo record',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          const Text(
            'A fictional neighbour profile. Only these shared demo readings and journal entries are visible here.',
          ),
        ],
      ),
    ),
  );
}

class NeighbourMapPainter extends CustomPainter {
  const NeighbourMapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 400, size.height / 310);
    final p = Paint()..isAntiAlias = true;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 310),
      p..color = const Color(0xFFEDF2E5),
    );
    for (final r in [
      const Rect.fromLTWH(28, 62, 94, 65),
      const Rect.fromLTWH(260, 30, 110, 90),
      const Rect.fromLTWH(234, 206, 135, 90),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(22)),
        p..color = const Color(0xFFD7E8CB),
      );
    }
    final river = Path()
      ..moveTo(0, 260)
      ..cubicTo(100, 310, 80, 145, 175, 190)
      ..cubicTo(260, 230, 295, 100, 410, 145);
    canvas.drawPath(
      river,
      p
        ..color = const Color(0xFFB9DBE1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32,
    );
    final road = Path()
      ..moveTo(0, 155)
      ..lineTo(126, 155)
      ..quadraticBezierTo(154, 155, 154, 105)
      ..lineTo(154, 0)
      ..moveTo(154, 108)
      ..lineTo(400, 108)
      ..moveTo(267, 108)
      ..lineTo(267, 310);
    canvas.drawPath(
      road,
      p
        ..color = Colors.white
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );
    for (final at in [
      const Offset(55, 91),
      const Offset(80, 87),
      const Offset(306, 58),
      const Offset(326, 68),
      const Offset(319, 254),
      const Offset(345, 240),
    ]) {
      canvas.drawCircle(
        at,
        10,
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF9AC18B),
      );
      canvas.drawCircle(
        at.translate(-2, -3),
        6,
        p..color = const Color(0xFFB1D2A0),
      );
    }
    canvas.drawCircle(
      const Offset(200, 155),
      110,
      p
        ..color = const Color(0x66377E43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(NeighbourMapPainter oldDelegate) => false;
}
