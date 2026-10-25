import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../models/sensor_gauge.dart';
import '../widgets/compact_sensor_status.dart';
import '../widgets/design.dart';
import '../widgets/milo.dart';

class HomePage extends StatefulWidget {
  final PlantController controller;
  final void Function(int) select;
  final VoidCallback openCare, openWeather, editProfile;
  const HomePage({
    super.key,
    required this.controller,
    required this.select,
    required this.openCare,
    required this.openWeather,
    required this.editProfile,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int direction = 1;
  PlantController get c => widget.controller;
  void step(int delta) {
    setState(() => direction = delta);
    unawaited(
      c.stepPlant(delta).then((saved) {
        if (!saved && mounted) feedback(context, false, '');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = c.data;
    final reduced =
        data.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Normal phone and desktop sizes use a fixed overview with no scrollable.
        // Extremely small windows / very large accessibility fonts retain a
        // fallback rather than clipping controls or shrinking text to unreadable size.
        final minimum = scale > 1.6
            ? 1200.0
            : scale > 1.3
            ? 950.0
            : scale > 1.15 && constraints.maxWidth < 400
            ? 900.0
            : 560.0;
        final height = math.max(constraints.maxHeight, minimum);
        final fallback = constraints.maxHeight < minimum;
        Widget allocateHero(Widget child) => fallback
            ? SizedBox(height: 300, child: child)
            : Expanded(child: child);
        final overview = SizedBox(
          height: fallback ? null : height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Column(
              mainAxisSize: fallback ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My plants',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${c.plants.length} ${c.plants.length == 1 ? 'companion' : 'companions'} · simulated',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF68776B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data.checkIns)
                      if (scale > 1.3)
                        IconButton.filledTonal(
                          tooltip: c.checkedToday
                              ? 'Care check recorded'
                              : 'Daily care check',
                          onPressed: c.checkedToday
                              ? null
                              : () => reportSave(
                                  context,
                                  c.checkIn(),
                                  'Daily care check recorded.',
                                ),
                          icon: Icon(
                            c.checkedToday
                                ? Icons.check_circle_outline_rounded
                                : Icons.favorite_border_rounded,
                          ),
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: c.checkedToday
                              ? null
                              : () => reportSave(
                                  context,
                                  c.checkIn(),
                                  'Daily care check recorded.',
                                ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: Icon(
                            c.checkedToday
                                ? Icons.check_circle_outline_rounded
                                : Icons.favorite_border_rounded,
                            size: 17,
                          ),
                          label: Text(
                            c.checkedToday ? 'Checked' : 'Check in',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 4),
                allocateHero(
                  Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 38,
                                ),
                                child: AnimatedSwitcher(
                                  key: ValueKey('plant-carousel-$reduced'),
                                  duration: reduced
                                      ? Duration.zero
                                      : const Duration(milliseconds: 320),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position:
                                              Tween<Offset>(
                                                begin: Offset(
                                                  (child.key ==
                                                              ValueKey(
                                                                c.activePlantId,
                                                              )
                                                          ? direction
                                                          : -direction) *
                                                      .16,
                                                  0,
                                                ),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeOutCubic,
                                                ),
                                              ),
                                          child: child,
                                        ),
                                      ),
                                  child: Milo(
                                    key: ValueKey(c.activePlantId),
                                    name: data.name,
                                    species: data.species,
                                    mood: c.emotion.mood,
                                    reducedMotion: reduced,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton.filledTonal(
                                tooltip: 'Previous plant',
                                onPressed: c.plants.length > 1
                                    ? () => step(-1)
                                    : null,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  backgroundColor: mint,
                                ),
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton.filledTonal(
                                tooltip: 'Next plant',
                                onPressed: c.plants.length > 1
                                    ? () => step(1)
                                    : null,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(44, 44),
                                  backgroundColor: mint,
                                ),
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: c.plants.length <= 7
                              ? [
                                  for (final plant in c.plants)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: plant.id == c.activePlantId
                                              ? leaf
                                              : const Color(0xFFCDD5C9),
                                        ),
                                      ),
                                    ),
                                ]
                              : [
                                  Text(
                                    '${c.activePlantIndex + 1} / ${c.plants.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              data.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit ${data.name}',
                            onPressed: widget.editProfile,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${data.profile.name} · ${c.emotion.mood}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68776B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final gauge in sensorGauges(data)) ...[
                  CompactSensorStatus(
                    key: ValueKey('compact-${gauge.id}'),
                    gauge: gauge,
                  ),
                  if (gauge.id != 'ph') const SizedBox(height: 6),
                ],
                const SizedBox(height: 8),
                Material(
                  color: const Color(0xFFFFF0CA),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: widget.openCare,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.spa_outlined, size: 18, color: leaf),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.care.first.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'Care Guide · tap for advice',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF68776B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return constraints.maxHeight >= minimum
            ? overview
            : SingleChildScrollView(child: overview);
      },
    );
  }
}
