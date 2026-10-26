import 'package:flutter/material.dart';
import '../../app/plant_controller.dart';
import '../../models/demo_growth.dart';
import '../../widgets/design.dart';
import 'growth_movie.dart';

class DemoStoryPanel extends StatelessWidget {
  final PlantController controller;
  final bool films;
  const DemoStoryPanel({
    super.key,
    required this.controller,
    this.films = false,
  });
  @override
  Widget build(BuildContext context) {
    final story = controller.data.demoStoryAt;
    final movie = controller.data.demoMovieAt;
    return SoftCard(
      color: films ? sky : mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Illustrated demo story', color: Colors.white),
          const SizedBox(height: 12),
          Text(
            story == null
                ? 'A small seed. A story to try.'
                : 'Sunny’s first season',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            story == null
                ? 'Add six sample memories for Sunny, a fictional marigold, and make a seed-to-bloom demo film.'
                : 'Six illustrated moments, from planting a seed to its first flower. This sample lives alongside your own memories.',
          ),
          const SizedBox(height: 14),
          if (story == null)
            OutlinedButton.icon(
              onPressed: () => reportSave(
                context,
                controller.addDemoStory(),
                'Six demo growth moments added.',
              ),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Add demo growth story'),
            )
          else ...[
            if (movie != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    growthCheckpoints.last.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GrowthMoviePage(),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch bloom film'),
              ),
              Text(
                '18 seconds · silent · created ${dateLabel(movie).substring(0, 10)}',
                style: const TextStyle(fontSize: 12),
              ),
            ] else
              FilledButton.icon(
                onPressed: () => reportSave(
                  context,
                  controller.createDemoMovie(),
                  'Demo film ready. Tap Watch bloom film.',
                ),
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text('Create demo film'),
              ),
            const SizedBox(height: 8),
            const Text(
              'The demo film uses bundled illustrated footage. Your selected plant’s real growth stage and care records stay separate.',
              style: TextStyle(fontSize: 12),
            ),
            TextButton.icon(
              onPressed: () => reportSave(
                context,
                controller.removeDemoStory(),
                'Demo story removed. You can add it again.',
              ),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Remove demo story'),
            ),
          ],
        ],
      ),
    );
  }
}

class DemoGrowthMoment extends StatelessWidget {
  final GrowthCheckpoint checkpoint;
  final DateTime addedAt;
  const DemoGrowthMoment({
    super.key,
    required this.checkpoint,
    required this.addedAt,
  });
  @override
  Widget build(BuildContext context) => SoftCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Tag('Demo memory', color: sky),
            const SizedBox(width: 8),
            Text('Day ${checkpoint.day}'),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(checkpoint.image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(checkpoint.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(checkpoint.note),
        const SizedBox(height: 10),
        Text(
          '${dateLabel(checkpoint.date(addedAt)).substring(0, 10)} · sample date',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
