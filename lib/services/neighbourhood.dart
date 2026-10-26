import 'dart:math' as math;
import '../models/plant_data.dart';
import '../models/plant_exchange.dart';
import 'engines.dart';

class SharedPlantLog {
  final int daysAgo;
  final String title, text;
  const SharedPlantLog(this.daysAgo, this.title, this.text);
}

class NearbyPlant {
  final String id, name, owner, species, place;
  final double east, north;
  final SensorReading reading;
  final List<SharedPlantLog> logs;
  const NearbyPlant({
    required this.id,
    required this.name,
    required this.owner,
    required this.species,
    required this.place,
    required this.east,
    required this.north,
    required this.reading,
    required this.logs,
  });
  int get distance => math.sqrt(east * east + north * north).round();
  PlantProfile get profile => plantProfiles.firstWhere((p) => p.id == species);
  List<CareTip> get care => CareEngine().evaluate(reading, profile);
  bool get comfortable => care.every((tip) => tip.priority == 0);
  String get status => comfortable ? 'Comfortable' : 'Care check';
  String get distanceLabel => distance < 1000
      ? '$distance m'
      : '${(distance / 1000).toStringAsFixed(1)} km';
}

const demoNeighbours = [
  NearbyPlant(
    id: 'fern',
    name: 'Fern',
    owner: 'June',
    species: 'pothos',
    place: 'Window Garden',
    east: -140,
    north: 120,
    reading: SensorReading(
      moisture: 52,
      light: 4800,
      temperature: 24,
      humidity: 62,
    ),
    logs: [
      SharedPlantLog(
        0,
        'A new leaf unfolded',
        'A heart-shaped leaf opened this morning. We turned the pot gently toward indirect light.',
      ),
      SharedPlantLog(
        3,
        'Our quiet Sunday',
        'June checked the topsoil before watering. Slow care is still care.',
      ),
    ],
  ),
  NearbyPlant(
    id: 'pip',
    name: 'Pip',
    owner: 'Kai',
    species: 'spider',
    place: 'Little Green Cafe',
    east: 310,
    north: -230,
    reading: SensorReading(
      moisture: 20,
      light: 6500,
      temperature: 25,
      humidity: 58,
    ),
    logs: [
      SharedPlantLog(
        0,
        'A dry afternoon',
        'The soil feels drier today. Kai is checking it before deciding how much water to add.',
      ),
      SharedPlantLog(
        2,
        'A tiny plantlet',
        'A little plantlet appeared beside my leaves. Our cafe family is growing.',
      ),
    ],
  ),
  NearbyPlant(
    id: 'luna',
    name: 'Luna',
    owner: 'Alex',
    species: 'snake',
    place: 'Reading Corner',
    east: -520,
    north: -430,
    reading: SensorReading(
      moisture: 27,
      light: 3200,
      temperature: 23,
      humidity: 48,
    ),
    logs: [
      SharedPlantLog(
        1,
        'A peaceful reading day',
        'A book, soft afternoon light, and a healthy dry-down between waterings.',
      ),
      SharedPlantLog(
        5,
        'A little dusting',
        'Alex wiped my leaves so they can catch the light again.',
      ),
    ],
  ),
  NearbyPlant(
    id: 'olive',
    name: 'Olive',
    owner: 'Sam',
    species: 'pothos',
    place: 'Riverside Studio',
    east: 920,
    north: 760,
    reading: SensorReading(
      moisture: 44,
      light: 6200,
      temperature: 26,
      humidity: 66,
    ),
    logs: [
      SharedPlantLog(
        0,
        'A longer vine',
        'My newest vine reached the edge of the shelf. Sam added a gentle support.',
      ),
      SharedPlantLog(
        4,
        'Rain at the window',
        'We enjoyed the sound of rain from indoors. No extra watering was needed.',
      ),
    ],
  ),
  NearbyPlant(
    id: 'sprout',
    name: 'Sprout',
    owner: 'Robin',
    species: 'spider',
    place: 'Sunny Courtyard',
    east: -1150,
    north: 940,
    reading: SensorReading(
      moisture: 55,
      light: 900,
      temperature: 24,
      humidity: 57,
    ),
    logs: [
      SharedPlantLog(
        0,
        'Finding brighter light',
        'My corner is a little dim. Robin is looking for a spot with bright, indirect light.',
      ),
      SharedPlantLog(
        6,
        'A fresh start',
        'We moved into the courtyard together and found a new routine.',
      ),
    ],
  ),
];

List<NearbyPlant> searchNeighbours({
  String query = '',
  int radius = 1000,
  bool careOnly = false,
}) {
  final q = query.trim().toLowerCase();
  return demoNeighbours
      .where(
        (n) =>
            n.distance <= radius &&
            (!careOnly || !n.comfortable) &&
            ('${n.name} ${n.owner} ${n.profile.name} ${n.place}'
                .toLowerCase()
                .contains(q)),
      )
      .toList()
    ..sort((a, b) => a.distance.compareTo(b.distance));
}

/// Only shared fixture logs/readings enter peer reviews, never private memories.
PlantExchange makePlantExchange(
  String id,
  DateTime at,
  PlantData local,
  NearbyPlant neighbour,
) {
  final own = CareEngine().evaluate(local.sensors, local.profile).first;
  final peer = neighbour.care.first;
  final peerReview = peer.priority == 0
      ? 'Your readings look comfortable for a ${neighbour.profile.name}. That new growth has a lovely place to start.'
      : '${peer.reason} ${peer.action} A small check could help.';
  final ownReview = own.priority == 0
      ? 'Your readings look comfortable for a ${local.profile.name}, too. Keep checking before changing your care routine.'
      : '${own.reason} ${own.action} Let your human check before doing anything.';
  return PlantExchange(
    id: id,
    neighbourId: neighbour.id,
    at: at,
    observation:
        '${neighbour.name}: ${neighbour.status.toLowerCase()} · ${peer.title}',
    lines: [
      PlantLine(
        local.name,
        'Hello, ${neighbour.name}! I saw your shared journal: “${neighbour.logs.first.title}”. How are you growing today?',
      ),
      PlantLine(
        neighbour.name,
        'Hello, ${local.name}! My soil is at ${neighbour.reading.moisture.round()}% and my light is ${neighbour.reading.light.round()} lux. ${neighbour.logs.first.text}',
      ),
      PlantLine(local.name, peerReview),
      PlantLine(neighbour.name, ownReview),
    ],
  );
}
