import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/services/local_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlantController c;
  late LocalRepository repo;
  late DateTime now;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = LocalRepository(await SharedPreferences.getInstance());
    now = DateTime(2026, 10, 24, 10);
    c = PlantController(repo, PlantData(), now: () => now);
  });
  tearDown(() async {
    await c.flush();
    c.dispose();
  });

  test(
    'dry preset propagates to care, mood and chat; healthy restores state',
    () async {
      await c.preset('Dry Soil');
      expect(c.data.sensors.moisture, 12);
      expect(c.care.first.title, 'Soil moisture is low');
      expect(c.emotion.mood, 'Thirsty');
      await c.send('How are you feeling today?');
      expect(c.data.messages.last.text, contains('12%'));
      await c.preset('Healthy Conditions');
      expect(c.care.single.priority, 0);
      expect(c.emotion.mood, 'Thriving');
    },
  );

  test(
    'species changes adjust every illustrative care rule without mutating sensors',
    () async {
      await c.sensors(const SensorReading(moisture: 25));
      expect(c.care.first.title, 'Soil moisture is low');
      await c.profile('Fern', 'snake', 'Playful', finish: true);
      expect(c.care.single.priority, 0);
      expect(c.data.sensors.moisture, 25);
      await c.send('Hello');
      expect(c.data.messages.last.text, contains('Fern'));
      expect(c.data.messages.last.text, contains('Snake Plant'));
      expect(c.data.messages.last.text, contains('Leaf high-five'));
    },
  );

  test(
    'explicit capture only; memory edit and deletion keep id and date',
    () async {
      await c.send('I love rainy mornings');
      expect(c.data.memories, isEmpty);
      await c.send('Remember that I love rainy mornings');
      expect(c.data.memories.single.text, 'I love rainy mornings');
      final entry = c.data.memories.single;
      await c.saveEntry('I love sunny mornings', memory: true, id: entry.id);
      expect(c.data.memories.single.id, entry.id);
      expect(c.data.memories.single.at, entry.at);
      await c.send('What do you remember?');
      expect(c.data.messages.last.text, contains('sunny mornings'));
      await c.deleteEntry(entry.id, memory: true);
      expect(c.data.memories, isEmpty);
    },
  );

  test(
    'agent handles empty memory request, unknown input, and distress safely',
    () async {
      await c.send('Remember that');
      expect(c.data.memories, isEmpty);
      expect(c.data.messages.last.text, contains('What would you like'));
      await c.send('quux xyz');
      expect(c.data.messages.last.text, contains('rule-based'));
      await c.send('I want to kill myself');
      expect(c.data.messages.last.text, contains('999'));
      expect(c.data.messages.last.text, contains('not professional help'));
      expect(c.data.memories, isEmpty);
    },
  );

  test(
    'weather preview does not change sensors; apply feeds downstream engines',
    () async {
      final before = c.data.sensors.toJson();
      await c.weather('Heatwave', 'Kowloon');
      expect(c.data.sensors.toJson(), before);
      await c.weather('Heatwave', 'Kowloon', apply: true);
      expect(c.data.sensors.temperature, 38);
      expect(c.care.any((t) => t.title == 'Temperature is high'), isTrue);
      expect(c.emotion.vitality, lessThan(100));
    },
  );

  test(
    'emotion scores stay bounded and deterministic, loneliness responds to time',
    () async {
      await c.checkIn();
      final first = c.emotion;
      expect(c.emotion.comfort, first.comfort);
      expect(c.emotion.loneliness, 0);
      now = now.add(const Duration(days: 5));
      expect(c.emotion.loneliness, 75);
      expect(c.emotion.mood, 'Missing you');
      await c.sensors(
        const SensorReading(
          moisture: 0,
          light: 0,
          temperature: 50,
          humidity: 0,
          ph: 14,
        ),
      );
      for (final value in [
        c.emotion.comfort,
        c.emotion.vitality,
        c.emotion.attachment,
        c.emotion.loneliness,
      ]) {
        expect(value, inInclusiveRange(0, 100));
      }
    },
  );

  test(
    'check-ins are date-idempotent; challenge is earned across three days',
    () async {
      await c.change(() => c.data.challengeJoined = true);
      await c.checkIn();
      await c.checkIn();
      expect(c.data.checkInDays.length, 1);
      expect(c.challengeComplete, isFalse);
      for (var i = 0; i < 2; i++) {
        now = now.add(const Duration(days: 1));
        await c.checkIn();
      }
      expect(c.challengeComplete, isTrue);
    },
  );

  test(
    'complete data survives reload including settings, interactions and snapshots',
    () async {
      await c.profile('Basil', 'spider', 'Thoughtful', finish: true);
      await c.preset('Low Light');
      await c.saveSnapshot();
      await c.saveEntry('First leaf', memory: false);
      await c.stage('Growing');
      await c.send('Remember that our first day was sunny');
      await c.weather('Rainy', 'New Territories');
      await c.addPost('A new leaf!');
      await c.interact(c.posts.first);
      await c.interact(c.posts.last, visit: true);
      await c.checkIn();
      await c.change(() {
        c.data.largeText = true;
        c.data.reducedMotion = true;
        c.data.sharing = true;
        c.data.checkIns = false;
        c.data.challengeJoined = true;
      });
      final reloaded = (await repo.load()).data;
      expect(jsonEncode(reloaded.toJson()), jsonEncode(c.data.toJson()));
      expect(reloaded.onboarded, isTrue);
      expect(reloaded.snapshots.single.reading.light, 180);
      expect(reloaded.messages.length, 2);
      expect(reloaded.posts.any((p) => p.visited), isTrue);
    },
  );

  test(
    'milestone edit/delete, scoped clearing and full reset are predictable',
    () async {
      await c.saveEntry('A new leaf', memory: false);
      final id = c.data.milestones.single.id;
      await c.saveEntry('Two new leaves', memory: false, id: id);
      expect(c.data.milestones.single.text, 'Two new leaves');
      await c.deleteEntry(id, memory: false);
      expect(c.data.milestones, isEmpty);
      await c.send('Remember my birthday');
      await c.saveSnapshot();
      await c.clear('memories');
      expect(c.data.memories, isEmpty);
      expect(c.data.messages.length, 2);
      await c.clear('chat');
      expect(c.data.messages, isEmpty);
      await c.clear('history');
      expect(c.data.snapshots, isEmpty);
      await c.profile('Fern', 'snake', 'Playful', finish: true);
      await c.clear('reset');
      expect(c.data.name, 'Milo');
      expect(c.data.onboarded, isFalse);
      expect(c.data.checkInDays, isEmpty);
      expect(c.data.posts, isEmpty);
      expect((await repo.load()).data.onboarded, isFalse);
    },
  );

  test(
    'malformed data is backed up and defaults load without crashing',
    () async {
      await repo.preferences.setString(LocalRepository.key, '{broken');
      final loaded = await repo.load();
      expect(loaded.warning, isNotNull);
      expect(loaded.data.name, 'Milo');
      expect(repo.preferences.getString(LocalRepository.key), '{broken');
      expect(
        repo.preferences.getKeys().where((k) => k.contains('_recovery_')),
        isNotEmpty,
      );
      final malformed = PlantData().toJson()
        ..['memories'] = [
          {'id': 3},
        ];
      await repo.preferences.setString(
        LocalRepository.key,
        jsonEncode(malformed),
      );
      expect((await repo.load()).warning, isNotNull);
    },
  );

  test('sensor deserialization constrains invalid and non-finite input', () {
    final s = SensorReading.fromJson({
      'moisture': -5,
      'light': 40000,
      'temperature': double.nan,
      'humidity': 'wet',
      'ph': 20,
    });
    expect(s.moisture, 0);
    expect(s.light, 30000);
    expect(s.temperature, 24);
    expect(s.humidity, 60);
    expect(s.ph, 14);
  });

  test(
    'failed storage is visible and retry persists the complete current state',
    () async {
      final failing = FailingRepository(repo.preferences);
      final state = PlantController(failing, PlantData());
      expect(await state.saveEntry('Keep this moment', memory: true), isFalse);
      expect(state.storageError, isNotNull);
      expect(state.data.memories.single.text, 'Keep this moment');
      failing.fail = false;
      expect(await state.retrySave(), isTrue);
      expect(state.storageError, isNull);
      expect((await repo.load()).data.memories.single.text, 'Keep this moment');
      state.dispose();
    },
  );

  test('concurrent edits persist in order and final snapshot wins', () async {
    final edits = [
      for (var i = 0; i < 15; i++)
        c.sensors(SensorReading(moisture: i.toDouble())),
    ];
    expect(await Future.wait(edits), everyElement(isTrue));
    expect((await repo.load()).data.sensors.moisture, 14);
  });
}

class FailingRepository extends LocalRepository {
  bool fail = true;
  FailingRepository(super.preferences);
  @override
  Future<void> save(String document) async {
    if (fail) throw StateError('Simulated disk failure');
    await super.save(document);
  }
}
