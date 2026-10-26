import 'dart:convert';
import 'plant_exchange.dart';

const personalities = ['Gentle', 'Playful', 'Thoughtful'];
const lifeStages = [
  'Early growth',
  'Growing',
  'Mature',
  'Resting',
  'Remembered',
];

class PlantProfile {
  final String id, name, description, guidance;
  final double minMoisture, maxMoisture, minLight, maxLight;
  final double minTemperature,
      maxTemperature,
      minHumidity,
      maxHumidity,
      minPh,
      maxPh;
  const PlantProfile(
    this.id,
    this.name,
    this.description,
    this.guidance,
    this.minMoisture,
    this.maxMoisture,
    this.minLight,
    this.maxLight,
    this.minTemperature,
    this.maxTemperature,
    this.minHumidity,
    this.maxHumidity,
    this.minPh,
    this.maxPh,
  );
}

const plantProfiles = [
  PlantProfile(
    'pothos',
    'Golden Pothos',
    'A trailing friend with heart-shaped leaves.',
    'Beginner friendly. Use indirect light and let the topsoil dry between watering. Keep away from pets that chew leaves.',
    30,
    65,
    1500,
    10000,
    18,
    30,
    40,
    80,
    6,
    7,
  ),
  PlantProfile(
    'snake',
    'Snake Plant',
    'An upright, easygoing companion for quieter corners.',
    'Good for busy beginners. Let soil dry well; avoid standing water. Leaves are unsafe for pets to eat.',
    15,
    40,
    500,
    12000,
    16,
    32,
    25,
    70,
    5.5,
    7.5,
  ),
  PlantProfile(
    'spider',
    'Spider Plant',
    'A bright, arching plant that grows little plantlets.',
    'A friendly indoor choice. Aim for even moisture and bright, indirect light. Protect from harsh afternoon sun.',
    35,
    70,
    2000,
    12000,
    18,
    28,
    40,
    80,
    6,
    7.5,
  ),
];

class SensorReading {
  final double moisture, light, temperature, humidity, ph;
  const SensorReading({
    this.moisture = 48,
    this.light = 4500,
    this.temperature = 24,
    this.humidity = 60,
    this.ph = 6.5,
  });
  SensorReading copyWith({
    double? moisture,
    double? light,
    double? temperature,
    double? humidity,
    double? ph,
  }) => SensorReading(
    moisture: moisture ?? this.moisture,
    light: light ?? this.light,
    temperature: temperature ?? this.temperature,
    humidity: humidity ?? this.humidity,
    ph: ph ?? this.ph,
  );
  Map<String, dynamic> toJson() => {
    'moisture': moisture,
    'light': light,
    'temperature': temperature,
    'humidity': humidity,
    'ph': ph,
  };
  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
    moisture: _number(j['moisture'], 48, 0, 100),
    light: _number(j['light'], 4500, 0, 30000),
    temperature: _number(j['temperature'], 24, 0, 50),
    humidity: _number(j['humidity'], 60, 0, 100),
    ph: _number(j['ph'], 6.5, 0, 14),
  );
}

double _number(dynamic v, double fallback, double min, double max) =>
    v is num && v.isFinite ? v.toDouble().clamp(min, max) : fallback;
String _text(dynamic value, String fallback) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;

class Entry {
  final String id, text, kind;
  final DateTime at;
  const Entry({
    required this.id,
    required this.text,
    required this.at,
    this.kind = 'note',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'at': at.toIso8601String(),
    'kind': kind,
  };
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
    id: j['id'] as String,
    text: j['text'] as String,
    at: DateTime.parse(j['at'] as String),
    kind: _text(j['kind'], 'note'),
  );
}

class Snapshot {
  final DateTime at;
  final SensorReading reading;
  const Snapshot(this.at, this.reading);
  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'reading': reading.toJson(),
  };
  factory Snapshot.fromJson(Map<String, dynamic> j) => Snapshot(
    DateTime.parse(j['at'] as String),
    SensorReading.fromJson(Map<String, dynamic>.from(j['reading'] as Map)),
  );
}

class LocalPost {
  final String id, author, text;
  final DateTime at;
  final bool sample;
  bool liked, visited;
  LocalPost({
    required this.id,
    required this.author,
    required this.text,
    required this.at,
    this.sample = false,
    this.liked = false,
    this.visited = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'text': text,
    'at': at.toIso8601String(),
    'sample': sample,
    'liked': liked,
    'visited': visited,
  };
  factory LocalPost.fromJson(Map<String, dynamic> j) => LocalPost(
    id: j['id'] as String,
    author: j['author'] as String,
    text: j['text'] as String,
    at: DateTime.parse(j['at'] as String),
    sample: j['sample'] == true,
    liked: j['liked'] == true,
    visited: j['visited'] == true,
  );
}

/// One versioned local document. Engines derive care and emotions from this state.
class PlantData {
  String name = 'Milo', species = 'pothos', personality = 'Gentle';
  String stage = 'Early growth', location = 'Hong Kong', weather = 'Sunny';
  bool onboarded = false, largeText = false, reducedMotion = false;
  bool checkIns = true, sharing = false, challengeJoined = false;
  DateTime? lastInteraction;
  SensorReading sensors = const SensorReading();
  List<Entry> memories = [], milestones = [], messages = [], activities = [];
  List<Snapshot> snapshots = [];
  List<String> checkInDays = [];
  List<LocalPost> posts = [];
  List<PlantExchange> plantExchanges = [];
  DateTime? demoStoryAt, demoMovieAt;
  PlantProfile get profile => plantProfiles.firstWhere((p) => p.id == species);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'name': name,
    'species': species,
    'personality': personality,
    'stage': stage,
    'location': location,
    'weather': weather,
    'onboarded': onboarded,
    'largeText': largeText,
    'reducedMotion': reducedMotion,
    'checkIns': checkIns,
    'sharing': sharing,
    'challengeJoined': challengeJoined,
    'lastInteraction': lastInteraction?.toIso8601String(),
    'sensors': sensors.toJson(),
    'memories': memories.map((v) => v.toJson()).toList(),
    'milestones': milestones.map((v) => v.toJson()).toList(),
    'messages': messages.map((v) => v.toJson()).toList(),
    'activities': activities.map((v) => v.toJson()).toList(),
    'snapshots': snapshots.map((v) => v.toJson()).toList(),
    'checkInDays': checkInDays,
    'posts': posts.map((v) => v.toJson()).toList(),
    'plantExchanges': plantExchanges.map((v) => v.toJson()).toList(),
    'demoStoryAt': demoStoryAt?.toIso8601String(),
    'demoMovieAt': demoMovieAt?.toIso8601String(),
  };

  factory PlantData.decode(String raw) {
    final j = jsonDecode(raw);
    if (j is! Map<String, dynamic> || j['version'] != 1) {
      throw const FormatException('Unknown local data format');
    }
    final d = PlantData();
    d.name = _text(j['name'], 'Milo');
    d.species = plantProfiles.any((p) => p.id == j['species'])
        ? j['species'] as String
        : 'pothos';
    d.personality = personalities.contains(j['personality'])
        ? j['personality'] as String
        : 'Gentle';
    d.stage = lifeStages.contains(j['stage'])
        ? j['stage'] as String
        : 'Early growth';
    d.location = _text(j['location'], 'Hong Kong');
    d.weather =
        ['Sunny', 'Rainy', 'Heatwave', 'Cool & cloudy'].contains(j['weather'])
        ? j['weather'] as String
        : 'Sunny';
    d.onboarded = j['onboarded'] == true;
    d.largeText = j['largeText'] == true;
    d.reducedMotion = j['reducedMotion'] == true;
    d.checkIns = j['checkIns'] != false;
    d.sharing = j['sharing'] == true;
    d.challengeJoined = j['challengeJoined'] == true;
    d.lastInteraction = DateTime.tryParse(
      j['lastInteraction']?.toString() ?? '',
    );
    if (j['sensors'] is Map) {
      d.sensors = SensorReading.fromJson(
        Map<String, dynamic>.from(j['sensors'] as Map),
      );
    }
    d.memories = _list(j['memories'], Entry.fromJson);
    d.milestones = _list(j['milestones'], Entry.fromJson);
    d.messages = _list(j['messages'], Entry.fromJson);
    d.activities = _list(j['activities'], Entry.fromJson);
    d.snapshots = _list(j['snapshots'], Snapshot.fromJson);
    d.posts = _list(j['posts'], LocalPost.fromJson);
    d.plantExchanges = _list(j['plantExchanges'], PlantExchange.fromJson);
    d.demoStoryAt = _optionalDate(j['demoStoryAt']);
    d.demoMovieAt = _optionalDate(j['demoMovieAt']);
    if (d.demoMovieAt != null && d.demoStoryAt == null) {
      throw const FormatException('A demo movie must have a story');
    }
    if (j['checkInDays'] is List) {
      d.checkInDays = (j['checkInDays'] as List)
          .whereType<String>()
          .where((s) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s))
          .toSet()
          .toList();
    }
    return d;
  }
  PlantData();
}

// Preserve the whole original document on parse failure rather than silently
// discarding malformed records and overwriting them with a partial document.
List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw == null) return [];
  if (raw is! List) throw const FormatException('Expected a list');
  return raw.map((v) => parse(Map<String, dynamic>.from(v as Map))).toList();
}

DateTime? _optionalDate(dynamic value) {
  if (value == null) return null;
  if (value is! String || DateTime.tryParse(value) == null) {
    throw const FormatException('Invalid story date');
  }
  return DateTime.parse(value);
}
