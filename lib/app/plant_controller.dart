import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/plant_data.dart';
import '../services/engines.dart';
import '../services/local_repository.dart';

class PlantController extends ChangeNotifier {
  final LocalRepository repository;
  final DateTime Function() clock;
  PlantData data;
  String? storageError, notice;
  Future<void>? _pending;
  int _serial = 0;
  PlantController(
    this.repository,
    this.data, {
    DateTime Function()? now,
    this.notice,
  }) : clock = now ?? DateTime.now;
  PlantEmotion get emotion => EmotionEngine().evaluate(data, clock());
  List<CareTip> get care => CareEngine().evaluate(data.sensors, data.profile);
  String get today => clock().toIso8601String().substring(0, 10);
  bool get checkedToday => data.checkInDays.contains(today);
  bool get challengeComplete =>
      data.challengeJoined && data.checkInDays.length >= 3;
  Entry entry(String text, [String kind = 'note']) => Entry(
    id: '${clock().microsecondsSinceEpoch}_${_serial++}',
    text: text.trim(),
    at: clock(),
    kind: kind,
  );
  void _activity(String text) {
    data.activities.add(entry(text, 'activity'));
    if (data.activities.length > 200) data.activities.removeAt(0);
  }

  /// Capture each complete document before queuing writes. A late earlier write
  /// can never overwrite a newer edit. Failed writes remain visible and retryable.
  Future<bool> change(VoidCallback edit) {
    edit();
    final document = jsonEncode(data.toJson());
    notifyListeners();
    final operation = (_pending ?? Future<void>.value()).then((_) async {
      try {
        await repository.save(document);
        storageError = null;
        notifyListeners();
        return true;
      } catch (_) {
        storageError =
            'Changes are in memory but could not be saved. Retry before closing the app.';
        notifyListeners();
        return false;
      }
    });
    _pending = operation.then((_) {});
    return operation;
  }

  void dismissNotice() {
    notice = null;
    notifyListeners();
  }

  Future<bool> retrySave() => change(() {});
  Future<void> flush() => _pending ?? Future<void>.value();
  Future<bool> profile(
    String name,
    String species,
    String personality, {
    bool finish = false,
  }) => change(() {
    data.name = name.trim().isEmpty ? 'Milo' : name.trim();
    data.species = plantProfiles.any((p) => p.id == species)
        ? species
        : 'pothos';
    data.personality = personalities.contains(personality)
        ? personality
        : 'Gentle';
    data.onboarded = data.onboarded || finish;
    _activity(
      finish
          ? 'Met ${data.name}. Our story begins!'
          : 'Updated ${data.name}’s profile.',
    );
  });
  Future<bool> sensors(SensorReading reading, {String? source}) => change(() {
    data.sensors = SensorReading.fromJson(reading.toJson());
    if (source != null) _activity('Applied $source (simulation).');
  });
  Future<bool> preset(String name) => sensors(
    name == 'Healthy Conditions'
        ? SensorService().healthy(data.profile)
        : SensorService.presets[name]!,
    source: name,
  );
  Future<bool> saveSnapshot() => change(() {
    data.snapshots.add(Snapshot(clock(), data.sensors));
    if (data.snapshots.length > 100) data.snapshots.removeAt(0);
    _activity('Saved a sensor snapshot.');
  });
  Future<bool> checkIn() => change(() {
    if (!checkedToday) {
      data.checkInDays.add(today);
      _activity('Completed a daily care check.');
    }
    data.lastInteraction = clock();
  });
  Future<bool> send(String text) async {
    if (text.trim().isEmpty) return false;
    return change(() {
      data.messages.add(entry(text, 'user'));
      final response = PlantAgent().respond(text, data, emotion);
      data.messages.add(entry(response.text, 'plant'));
      if (response.memory != null) {
        data.memories.add(entry(response.memory!));
        _activity('Planted a memory from chat.');
      }
      data.lastInteraction = clock();
    });
  }

  Future<bool> saveEntry(
    String text, {
    required bool memory,
    String? id,
  }) => change(() {
    final entries = memory ? data.memories : data.milestones;
    if (id == null) {
      entries.add(entry(text, memory ? 'note' : 'milestone'));
    } else {
      final index = entries.indexWhere((e) => e.id == id);
      if (index >= 0) {
        entries[index] = Entry(
          id: id,
          text: text.trim(),
          at: entries[index].at,
          kind: entries[index].kind,
        );
      }
    }
    data.lastInteraction = clock();
    _activity(
      '${id == null ? 'Added' : 'Edited'} a ${memory ? 'memory' : 'milestone'}.',
    );
  });
  Future<bool> deleteEntry(String id, {required bool memory}) => change(() {
    (memory ? data.memories : data.milestones).removeWhere((e) => e.id == id);
    _activity('Removed a ${memory ? 'memory' : 'milestone'}.');
  });
  Future<bool> stage(String stage) => change(() {
    if (lifeStages.contains(stage) && data.stage != stage) {
      data.stage = stage;
      data.milestones.add(entry('Life stage: $stage', 'stage'));
      _activity('Life stage changed to $stage.');
    }
  });
  Future<bool> weather(String name, String location, {bool apply = false}) =>
      change(() {
        data.weather = name;
        data.location = location;
        if (apply) {
          data.sensors = weatherScenarios
              .firstWhere((w) => w.name == name)
              .reading;
          _activity('Applied $name weather in $location to the Sensor Lab.');
        }
      });
  Future<bool> addPost(String text) => change(() {
    data.posts.add(
      LocalPost(
        id: entry('').id,
        author: '${data.name} & me',
        text: text.trim(),
        at: clock(),
      ),
    );
  });
  List<LocalPost> get posts => [
    ...data.posts.reversed,
    for (final seed in [
      ('seed-1', 'June & Fern', 'A new leaf unfolded today. Small joys count!'),
      (
        'seed-2',
        'Kai & Sprout',
        'I checked the soil before watering. A gentle routine goes a long way.',
      ),
    ])
      if (!data.posts.any((p) => p.id == seed.$1))
        LocalPost(
          id: seed.$1,
          author: seed.$2,
          text: seed.$3,
          at: DateTime(2026, 9, 25),
          sample: true,
        ),
  ];
  Future<bool> interact(LocalPost post, {bool visit = false}) => change(() {
    final stored = data.posts.where((p) => p.id == post.id).firstOrNull;
    final target = stored ?? post;
    if (stored == null) data.posts.add(target);
    if (visit) {
      target.visited = true;
    } else {
      target.liked = !target.liked;
    }
  });
  Future<bool> clear(String section) => change(() {
    switch (section) {
      case 'memories':
        data.memories.clear();
      case 'chat':
        data.messages.clear();
      case 'history':
        data.snapshots.clear();
        data.activities.clear();
      case 'reset':
        data = PlantData();
    }
  });
  String get journeySummary =>
      '${data.name} · ${data.profile.name}\nLife stage: ${data.stage}\n'
      '${data.checkInDays.length} care days · ${data.snapshots.length} sensor snapshots\n'
      '${data.milestones.map((e) => '${dateLabel(e.at)} — ${e.text}').join('\n')}\n'
      'Memories\n${data.memories.map((e) => '${dateLabel(e.at)} — ${e.text}').join('\n')}';
  String get dataSummary =>
      'Plant Heart · local data only\n${data.name} · ${data.profile.name}\n'
      '${data.memories.length} memories · ${data.milestones.length} milestones\n'
      '${data.messages.length} chat messages · ${data.snapshots.length} snapshots\n'
      '${data.posts.where((p) => !p.sample).length} local posts · ${data.checkInDays.length} care days\n'
      'Stored on this device using shared preferences; not encrypted or cloud backed up.\n'
      'Sharing and check-in preferences do not enable network sharing or system notifications.';
}

String dateLabel(DateTime date) {
  final d = date.toLocal();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
