import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../widgets/design.dart';
import '../widgets/milo.dart';

class HomePage extends StatelessWidget {
  final PlantController controller;
  final void Function(int) select;
  final VoidCallback openCare, openWeather;
  const HomePage({
    super.key,
    required this.controller,
    required this.select,
    required this.openCare,
    required this.openWeather,
  });
  @override
  Widget build(BuildContext context) {
    final d = controller.data, emotion = controller.emotion;
    final tip = controller.care.first;
    final hour = controller.clock().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return PageBody(
      eyebrow: 'A LITTLE CARE GOES A LONG WAY',
      title: '$greeting,\nlet’s grow a little.',
      subtitle: '${d.name} is happy you’re here.',
      children: [
        SoftCard(
          color: mint,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_rounded, color: leaf, size: 20),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'YOUR PLANT PAL',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Tag(emotion.mood, color: Colors.white),
                ],
              ),
              Milo(
                mood: emotion.mood,
                name: d.name,
                reducedMotion: d.reducedMotion,
              ),
              Text(d.name, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                d.profile.name,
                style: const TextStyle(color: Color(0xFF52664F)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  emotion.mood == 'Thirsty'
                      ? '“A little soil check? My pot is feeling dry.”'
                      : emotion.mood == 'Sleepy'
                      ? '“A gentler spot would help me perk up.”'
                      : '“No rush. We’re growing at our own pace.”',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Tag('Soil ${d.sensors.moisture.round()}%', color: sky),
            Tag('${d.sensors.temperature.round()}°C', color: sun),
            Tag('${d.sensors.light.round()} lux'),
            const Tag('Simulated', color: coral),
          ],
        ),
        SoftCard(
          color: sun,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ONE SMALL THING',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(tip.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(tip.action),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: openCare,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Open Care Guide'),
              ),
            ],
          ),
        ),
        const SectionTitle('Little moments, big roots'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text('Talk to ${d.name}'),
              onPressed: () => select(2),
            ),
            ActionChip(
              avatar: const Icon(Icons.tune_rounded),
              label: const Text('Sensor Lab'),
              onPressed: () => select(1),
            ),
            ActionChip(
              avatar: const Icon(Icons.auto_stories_outlined),
              label: const Text('Our journey'),
              onPressed: () => select(3),
            ),
            ActionChip(
              avatar: const Icon(Icons.wb_sunny_outlined),
              label: const Text('Weather'),
              onPressed: openWeather,
            ),
          ],
        ),
        if (d.checkIns)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: leaf),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your daily little check-in',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${d.checkInDays.length} care days together. Read the care tip, then check in. This records a visit, not real watering.',
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: controller.checkedToday ? 1 : 0,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: controller.checkedToday
                      ? null
                      : () async {
                          await reportSave(
                            context,
                            controller.checkIn(),
                            'Daily care check recorded.',
                          );
                        },
                  icon: Icon(
                    controller.checkedToday
                        ? Icons.check_circle_rounded
                        : Icons.favorite_border_rounded,
                  ),
                  label: Text(
                    controller.checkedToday
                        ? 'Today’s care check is done'
                        : 'I’ve checked on my plant',
                  ),
                ),
              ],
            ),
          ),
        SoftCard(
          color: sky,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Growing together',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('${d.stage} · ${d.memories.length} memories planted'),
              if (d.activities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(d.activities.last.text),
                Text(
                  dateLabel(d.activities.last.at),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        ExpansionTile(
          title: const Text('Behind this little mood'),
          tilePadding: EdgeInsets.zero,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tag('Comfort ${emotion.comfort}'),
                Tag('Vitality ${emotion.vitality}'),
                Tag('Attachment ${emotion.attachment}'),
                Tag('Loneliness ${emotion.loneliness}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(emotion.explanation),
          ],
        ),
      ],
    );
  }
}
