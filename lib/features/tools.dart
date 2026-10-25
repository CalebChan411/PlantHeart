import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../models/plant_data.dart';
import '../services/engines.dart';
import '../widgets/design.dart';

class CarePage extends StatelessWidget {
  final PlantController controller;
  const CarePage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'A little care,\na happier plant.',
    subtitle:
        'For your ${controller.data.profile.name}, based on its latest readings.',
    eyebrow: 'THE CARE GUIDE',
    children: [
      const Tag('Illustrative prototype rules', color: sun),
      for (final tip in controller.care)
        SoftCard(
          color: tip.priority == 0 ? mint : sun,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag(
                tip.priority == 0 ? 'Looking good' : 'Needs attention',
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(tip.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(tip.reason),
              const SizedBox(height: 12),
              Text(
                tip.action,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      const Text(
        'These ranges explain this simulator’s decisions; they are not validated scientific thresholds. Check the real plant and growing medium before taking action.',
      ),
      SoftCard(child: Text(controller.data.profile.guidance)),
    ],
  );
}

class WeatherPage extends StatelessWidget {
  final PlantController controller;
  const WeatherPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final d = controller.data;
    final w = weatherScenarios.firstWhere((w) => w.name == d.weather);
    const locations = ['Hong Kong', 'Kowloon', 'New Territories'];
    return PageBody(
      title: 'A change in\nthe weather.',
      subtitle: 'Explore what a different day could feel like.',
      eyebrow: 'MAKE YOUR OWN FORECAST',
      children: [
        const Tag('Simulated weather · never a live forecast', color: sky),
        DropdownButtonFormField<String>(
          initialValue: locations.contains(d.location)
              ? d.location
              : locations.first,
          decoration: const InputDecoration(labelText: 'Simulated location'),
          isExpanded: true,
          items: [
            for (final location in locations)
              DropdownMenuItem(value: location, child: Text(location)),
          ],
          onChanged: (v) => controller.weather(d.weather, v!),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final scenario in weatherScenarios)
              ChoiceChip(
                label: Text(scenario.name),
                selected: d.weather == scenario.name,
                onSelected: (_) =>
                    controller.weather(scenario.name, d.location),
              ),
          ],
        ),
        SoftCard(
          color: sky,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                w.name == 'Rainy'
                    ? Icons.water_drop_outlined
                    : Icons.wb_sunny_outlined,
                size: 42,
                color: leaf,
              ),
              const SizedBox(height: 16),
              Text(
                '${w.reading.temperature.round()}°C · ${w.name}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(d.location),
              const SizedBox(height: 16),
              Text(
                'Rain ${w.rain}\nHumidity ${w.reading.humidity.round()}%\nWind ${w.wind}\nUV ${w.uv}',
              ),
              const SizedBox(height: 18),
              Text(w.reminder),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            await reportSave(
              context,
              controller.weather(d.weather, d.location, apply: true),
              'Weather scenario applied to sensors, care and mood.',
            );
          },
          icon: const Icon(Icons.science_outlined),
          label: const Text('Apply scenario to readings'),
        ),
        const Text(
          'Selecting previews and saves a scenario. Apply changes all five simulated readings. Locations are labels only; no location permissions or weather services are used.',
        ),
      ],
    );
  }
}

class LibraryPage extends StatelessWidget {
  final PlantController controller;
  const LibraryPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Find your\nkind of green.',
    subtitle: 'Three little personalities, ready to grow with you.',
    eyebrow: 'THE PLANT LIBRARY',
    children: [
      const Tag('Local profiles · illustrative guidance', color: sun),
      for (final p in plantProfiles)
        SoftCard(
          color: p.id == controller.data.species ? mint : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco_rounded, color: leaf, size: 34),
              const SizedBox(height: 12),
              Text(p.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(p.description),
              const SizedBox(height: 12),
              Text(p.guidance),
              const SizedBox(height: 12),
              Text(
                'Demo moisture ${p.minMoisture.round()}–${p.maxMoisture.round()}%\nIndirect light ${p.minLight.round()}–${p.maxLight.round()} lux',
              ),
              const SizedBox(height: 8),
              Text(
                '${CareEngine().evaluate(controller.data.sensors, p).where((t) => t.priority > 0).length} readings outside demo ranges. Local suitability heuristic, not a scientific score.',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: p.id == controller.data.species
                    ? null
                    : () async {
                        await reportSave(
                          context,
                          controller.profile(
                            controller.data.name,
                            p.id,
                            controller.data.personality,
                          ),
                          '${p.name} selected; care rules updated.',
                        );
                      },
                child: Text(
                  p.id == controller.data.species
                      ? 'Your current plant'
                      : 'Choose this species',
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class CommunityPage extends StatelessWidget {
  final PlantController controller;
  const CommunityPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Good things\ngrow together.',
    subtitle: 'A little inspiration from our make-believe neighborhood.',
    eyebrow: 'THE LOCAL COMMUNITY',
    children: [
      const Tag('Local demo · no posts leave this device', color: coral),
      SoftCard(
        color: sun,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('The 3-day gentle care club'),
            const SizedBox(height: 8),
            Text(
              controller.challengeComplete
                  ? 'You completed the local challenge! Three real check-in days, one gentle routine.'
                  : '${controller.data.checkInDays.length.clamp(0, 3)}/3 care days recorded. Visit Home and check in on three different days. No need to water every day.',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: controller.data.checkInDays.length.clamp(0, 3) / 3,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: controller.data.challengeJoined
                  ? null
                  : () async {
                      await reportSave(
                        context,
                        controller.change(
                          () => controller.data.challengeJoined = true,
                        ),
                        'Joined the local care challenge.',
                      );
                    },
              child: Text(
                controller.challengeComplete
                    ? 'Challenge complete'
                    : controller.data.challengeJoined
                    ? 'You’re in · keep growing'
                    : 'Join local challenge',
              ),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: () async {
          final text = await editText(
            context,
            title: 'Share a little moment',
            hint: 'What’s growing in your world?',
          );
          if (text != null && context.mounted) {
            await reportSave(
              context,
              controller.addPost(text),
              'Post saved on this device only.',
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create local post'),
      ),
      for (final post in controller.posts)
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: mint,
                    child: Icon(Icons.local_florist_outlined, color: leaf),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      post.author,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.text),
              const SizedBox(height: 10),
              Text(
                '${post.sample ? 'Sample post' : 'Your local post'} · ${dateLabel(post.at)}',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await reportSave(
                        context,
                        controller.interact(post),
                        post.liked
                            ? 'Like saved locally.'
                            : 'Like removed locally.',
                      );
                    },
                    icon: Icon(
                      post.liked ? Icons.favorite : Icons.favorite_border,
                    ),
                    label: Text(post.liked ? 'Liked' : 'Like'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await controller.interact(post, visit: true);
                      if (context.mounted) {
                        feedback(
                          context,
                          ok,
                          'Virtual visit recorded locally. A little hello from ${controller.data.name}!',
                        );
                      }
                    },
                    icon: Icon(
                      post.visited
                          ? Icons.check_circle_outline
                          : Icons.waving_hand_outlined,
                    ),
                    label: Text(
                      post.visited ? 'Visited · visit again' : 'Virtual visit',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      const Text(
        'Visits and likes are local interactions with demo posts. Real users, cross-device sharing and cooperative networking are future integrations.',
      ),
    ],
  );
}
