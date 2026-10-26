import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/models/demo_growth.dart';
import 'package:plant_heart/services/local_repository.dart';
import 'package:plant_heart/services/neighbourhood.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlantController c;
  late LocalRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = LocalRepository(await SharedPreferences.getInstance());
    c = PlantController(
      repo,
      PlantData(),
      now: () => DateTime(2026, 10, 26, 12),
    );
  });
  tearDown(() async {
    await c.flush();
    c.dispose();
  });
  test(
    'demo search respects radius, query, care filter and nearest-first order',
    () {
      expect(searchNeighbours(radius: 500).map((p) => p.id), ['fern', 'pip']);
      expect(searchNeighbours().map((p) => p.id), ['fern', 'pip', 'luna']);
      expect(searchNeighbours(radius: 2000), hasLength(5));
      expect(
        searchNeighbours(radius: 2000, query: 'ROBIN').single.id,
        'sprout',
      );
      expect(searchNeighbours(radius: 2000, query: 'spider').map((p) => p.id), [
        'pip',
        'sprout',
      ]);
      expect(searchNeighbours(radius: 2000, careOnly: true).map((p) => p.id), [
        'pip',
        'sprout',
      ]);
      expect(searchNeighbours(query: 'no such place'), isEmpty);
      expect(searchNeighbours(query: 'Robin'), isEmpty);
    },
  );
  test(
    'peer observations use each species ranges and exclude private records',
    () {
      final local = PlantData()
        ..species = 'snake'
        ..sensors = const SensorReading(moisture: 25)
        ..memories = [
          Entry(id: 'secret', text: 'PRIVATE MEMORY', at: DateTime(2026)),
        ]
        ..messages = [
          Entry(id: 'chat', text: 'PRIVATE CHAT', at: DateTime(2026)),
        ];
      final result = makePlantExchange(
        'id',
        DateTime(2026),
        local,
        demoNeighbours[1],
      );
      expect(result.lines, hasLength(4));
      expect(result.lines[1].text, contains('20%'));
      expect(result.lines[2].text, contains('35'));
      expect(result.lines.last.text, contains('comfortable'));
      expect(jsonEncode(result.toJson()), isNot(contains('PRIVATE')));
      local.species = 'pothos';
      final dry = makePlantExchange(
        'id2',
        DateTime(2026),
        local,
        demoNeighbours[1],
      );
      expect(dry.lines.last.text, contains('25%'));
      expect(dry.lines.last.text, isNot(result.lines.last.text));
    },
  );
  test(
    'automatic exchanges stay bounded and do not earn care or change private state',
    () async {
      final before = c.data.toJson()..remove('plantExchanges');
      for (var i = 0; i < 62; i++) {
        await c.exchangeWith(demoNeighbours[i % 5]);
      }
      expect(c.data.plantExchanges, hasLength(60));
      final after = c.data.toJson()..remove('plantExchanges');
      expect(jsonEncode(after), jsonEncode(before));
      expect((await repo.load()).data.plantExchanges, hasLength(60));
    },
  );
  test(
    'demo story and movie are idempotent and keep real memories and growth intact',
    () async {
      await c.saveEntry('Our real first day', memory: true);
      final before = c.data.memories.single;
      expect(await c.createDemoMovie(), isFalse);
      await c.addDemoStory();
      final first = c.data.demoStoryAt;
      await c.addDemoStory();
      expect(c.data.demoStoryAt, first);
      await c.createDemoMovie();
      final made = c.data.demoMovieAt;
      await c.createDemoMovie();
      expect(c.data.demoMovieAt, made);
      expect(c.data.stage, 'Early growth');
      expect(c.data.checkInDays, isEmpty);
      expect(c.data.memories.single, same(before));
      expect(
        growthCheckpoints.last
            .date(first!)
            .difference(growthCheckpoints.first.date(first))
            .inDays,
        42,
      );
      await c.removeDemoStory();
      expect(c.data.demoMovieAt, isNull);
      expect(c.data.demoStoryAt, isNull);
      expect(c.data.memories.single, same(before));
    },
  );
  test(
    'neighbour exchanges and demo movie survive reload and stay per plant',
    () async {
      final original = c.activePlantId;
      await c.addDemoStory();
      await c.createDemoMovie();
      await c.exchangeWith(demoNeighbours.first);
      await c.addPlant('New fern', 'snake', 'Gentle');
      expect(c.data.plantExchanges, isEmpty);
      expect(c.data.demoMovieAt, isNull);
      await c.selectPlant(original);
      final loaded = await repo.load();
      expect(loaded.data.plantExchanges.single.lines.first.speaker, 'Milo');
      expect(loaded.data.demoStoryAt, isNotNull);
      expect(loaded.data.demoMovieAt, isNotNull);
      await c.clear('memories');
      expect(c.data.demoStoryAt, isNull);
      expect(c.data.demoMovieAt, isNull);
      expect(c.data.plantExchanges, hasLength(1));
    },
  );
  test(
    'legacy documents default new fields; malformed extensions preserve recovery',
    () async {
      final legacy = c.data.toJson()
        ..remove('plantExchanges')
        ..remove('demoStoryAt')
        ..remove('demoMovieAt');
      final decoded = PlantData.decode(jsonEncode(legacy));
      expect(decoded.plantExchanges, isEmpty);
      expect(decoded.demoMovieAt, isNull);
      final invalid = c.data.toJson()
        ..['plantExchanges'] = [
          {'id': 7},
        ];
      final raw = jsonEncode(invalid);
      await repo.preferences.setString(LocalRepository.key, raw);
      expect((await repo.load()).warning, isNotNull);
      expect(repo.preferences.getString(LocalRepository.key), raw);
      expect(
        () => PlantData.decode(
          jsonEncode(c.data.toJson()..['demoMovieAt'] = '2026-10-26T12:00:00'),
        ),
        throwsFormatException,
      );
    },
  );
}
