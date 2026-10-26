class GrowthCheckpoint {
  final int day, index;
  final String title, note;
  const GrowthCheckpoint(this.index, this.day, this.title, this.note);
  String get image => 'assets/demo_growth/stage_$index.png';
  Duration get position => Duration(seconds: index * 3);
  DateTime date(DateTime addedAt) => DateTime(
    addedAt.year,
    addedAt.month,
    addedAt.day,
  ).subtract(Duration(days: 42 - day));
}

/// A fictional flowering plant, not a claim that the selected species flowered.
const growthCheckpoints = [
  GrowthCheckpoint(
    0,
    0,
    'A seed and a beginning',
    'We planted a marigold seed and made a little space for something new.',
  ),
  GrowthCheckpoint(
    1,
    4,
    'Hello, little sprout',
    'A tiny green shoot appeared. We checked the soil before watering.',
  ),
  GrowthCheckpoint(
    2,
    10,
    'Our first leaves',
    'Two small leaves opened toward the light. A quiet little celebration.',
  ),
  GrowthCheckpoint(
    3,
    18,
    'Growing stronger',
    'More leaves, a taller stem, and a gentle daily care routine.',
  ),
  GrowthCheckpoint(
    4,
    28,
    'A promise of a flower',
    'The first bud appeared. Some changes are worth waiting for.',
  ),
  GrowthCheckpoint(
    5,
    42,
    'Our first bloom',
    'A golden flower opened. From a tiny seed to a shared memory.',
  ),
];
const growthMovieAsset = 'assets/demo_growth/seed_to_bloom.mp4';
