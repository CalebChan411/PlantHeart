import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/models/plant_collection.dart';
import 'package:plant_heart/services/local_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalRepository repo;
  late PlantController c;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = LocalRepository(await SharedPreferences.getInstance());
    c = PlantController(
      repo,
      PlantData()..onboarded = true,
      now: () => DateTime(2026, 10, 25),
    );
  });
  tearDown(() async {
    await c.flush();
    c.dispose();
  });
  test(
    'legacy data migrates without loss and is backed up before first version-2 write',
    () async {
      final legacy = PlantData()
        ..onboarded = true
        ..name = 'Original Milo'
        ..sensors = const SensorReading(moisture: 12)
        ..memories = [
          Entry(id: 'old', text: 'A first day', at: DateTime(2026, 1, 1)),
        ];
      final raw = jsonEncode(legacy.toJson());
      await repo.preferences.setString(LocalRepository.key, raw);
      final loaded = await repo.load();
      expect(loaded.warning, isNull);
      expect(loaded.collection.plants.length, 1);
      expect(jsonEncode(loaded.data.toJson()), raw);
      final migrated = PlantController(
        repo,
        loaded.data,
        collection: loaded.collection,
      );
      try {
        final id = migrated.activePlantId;
        await migrated.addPlant('Fern', 'snake', 'Playful');
        expect(
          repo.preferences.getString(
            '${LocalRepository.key}_before_multi_plant',
          ),
          raw,
        );
        expect(
          jsonDecode(
            repo.preferences.getString(LocalRepository.key)!,
          )['version'],
          2,
        );
        await migrated.selectPlant(id);
        expect(jsonEncode(migrated.data.toJson()), raw);
      } finally {
        await migrated.flush();
        migrated.dispose();
      }
    },
  );
  test(
    'plants retain independent readings, chat, memories, milestones, care and community state',
    () async {
      final first = c.activePlantId;
      await c.preset('Dry Soil');
      await c.saveSnapshot();
      await c.send('Remember that Milo has a new leaf');
      await c.stage('Mature');
      await c.checkIn();
      await c.addPost('Milo’s day');
      await c.weather('Rainy', 'Kowloon');
      final original = jsonEncode(c.data.toJson());
      await c.addPlant('Fern', 'snake', 'Thoughtful');
      final second = c.activePlantId;
      expect(c.data.memories, isEmpty);
      expect(c.data.messages, isEmpty);
      expect(c.data.snapshots, isEmpty);
      expect(c.data.milestones, isEmpty);
      expect(c.data.checkInDays, isEmpty);
      expect(c.data.posts, isEmpty);
      expect(c.care.first.priority, 0);
      expect(c.pixelDisplay.frame.name, 'Fern');
      await c.send('Remember that Fern likes the desk');
      await c.stage('Growing');
      await c.weather('Heatwave', 'Hong Kong', apply: true);
      final fern = jsonEncode(c.data.toJson());
      await c.selectPlant(first);
      expect(jsonEncode(c.data.toJson()), original);
      expect(c.emotion.mood, 'Thirsty');
      expect(c.pixelDisplay.frame.name, 'Milo');
      await c.selectPlant(second);
      expect(jsonEncode(c.data.toJson()), fern);
      expect(c.data.sensors.temperature, 38);
    },
  );
  test('collection reload restores active selection and every plant', () async {
    await c.addPlant('Fern', 'snake', 'Gentle');
    await c.send('Remember my desk');
    await c.addPlant('Pip', 'spider', 'Playful');
    await c.saveEntry('First plantlet', memory: false);
    await c.stepPlant(-1);
    final expected = c.activePlantId;
    final loaded = await repo.load();
    final restarted = PlantController(
      repo,
      loaded.data,
      collection: loaded.collection,
    );
    try {
      expect(restarted.plants.length, 3);
      expect(restarted.activePlantId, expected);
      expect(restarted.data.memories.single.text, 'my desk');
      await restarted.stepPlant(1);
      expect(restarted.data.name, 'Pip');
      expect(restarted.data.milestones.single.text, 'First plantlet');
    } finally {
      await restarted.flush();
      restarted.dispose();
    }
  });
  test(
    'arrows wrap; accessibility preferences stay consistent across plants',
    () async {
      final first = c.activePlantId;
      await c.addPlant('Fern', 'snake', 'Gentle');
      final second = c.activePlantId;
      await c.change(() {
        c.data.largeText = true;
        c.data.reducedMotion = true;
        c.data.checkIns = false;
      });
      await c.stepPlant(1);
      expect(c.activePlantId, first);
      expect(c.data.largeText, isTrue);
      expect(c.data.checkIns, isFalse);
      await c.stepPlant(-1);
      expect(c.activePlantId, second);
      expect(c.data.reducedMotion, isTrue);
      expect(await c.selectPlant('missing'), isFalse);
      expect(c.activePlantId, second);
    },
  );
  test('rapid switches and edits save complete documents in order', () async {
    final first = c.activePlantId;
    await c.addPlant('Fern', 'snake', 'Gentle');
    final second = c.activePlantId;
    final writes = [
      c.selectPlant(first),
      c.sensors(const SensorReading(moisture: 10)),
      c.selectPlant(second),
      c.sensors(const SensorReading(moisture: 20)),
      c.selectPlant(first),
    ];
    expect(await Future.wait(writes), everyElement(isTrue));
    final loaded = await repo.load();
    expect(loaded.collection.activeId, first);
    expect(loaded.collection.plants.first.data.sensors.moisture, 10);
    expect(loaded.collection.plants.last.data.sensors.moisture, 20);
  });
  test(
    'reset clears all plants; scoped clearing affects only the selected one',
    () async {
      await c.send('Remember Milo');
      final first = c.activePlantId;
      await c.addPlant('Fern', 'snake', 'Gentle');
      await c.send('Remember Fern');
      await c.clear('memories');
      expect(c.data.memories, isEmpty);
      await c.selectPlant(first);
      expect(c.data.memories.single.text, 'Milo');
      await c.clear('reset');
      expect(c.plants.length, 1);
      expect(c.data.name, 'Milo');
      expect(c.data.onboarded, isFalse);
      expect((await repo.load()).collection.plants.length, 1);
    },
  );
  test(
    'invalid collection membership preserves unreadable originals',
    () async {
      final bad = jsonEncode({
        'version': 2,
        'activeId': 'missing',
        'plants': [
          {'id': 'one', 'data': PlantData().toJson()},
          {'id': 'one', 'data': PlantData().toJson()},
        ],
      });
      expect(() => PlantCollection.decode(bad), throwsFormatException);
      await repo.preferences.setString(LocalRepository.key, bad);
      final loaded = await repo.load();
      expect(loaded.warning, isNotNull);
      expect(repo.preferences.getString(LocalRepository.key), bad);
      expect(
        repo.preferences.getKeys().where((k) => k.contains('_recovery_')),
        isNotEmpty,
      );
    },
  );
}
