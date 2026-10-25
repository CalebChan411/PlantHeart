import 'dart:convert';
import 'plant_data.dart';

class PlantRecord {
  final String id;
  PlantData data;
  PlantRecord(this.id, this.data);
  Map<String, dynamic> toJson() => {'id': id, 'data': data.toJson()};
}

/// Version 2 wraps the existing version-1 per-plant documents without changing
/// their records. A legacy single plant becomes the first collection member.
class PlantCollection {
  final List<PlantRecord> plants;
  String activeId;
  PlantCollection(this.plants, this.activeId);
  factory PlantCollection.single(PlantData data) =>
      PlantCollection([PlantRecord('plant-1', data)], 'plant-1');
  PlantRecord get active => plants.firstWhere((p) => p.id == activeId);
  Map<String, dynamic> toJson() => {
    'version': 2,
    'activeId': activeId,
    'plants': plants.map((p) => p.toJson()).toList(),
  };
  factory PlantCollection.decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid plant collection');
    }
    if (json['version'] == 1) {
      return PlantCollection.single(PlantData.decode(raw));
    }
    if (json['version'] != 2 || json['plants'] is! List) {
      throw const FormatException('Unknown plant collection format');
    }
    final records = (json['plants'] as List).map((value) {
      final row = Map<String, dynamic>.from(value as Map);
      final id = row['id'] as String;
      if (id.trim().isEmpty) throw const FormatException('Missing plant ID');
      return PlantRecord(id, PlantData.decode(jsonEncode(row['data'])));
    }).toList();
    final activeId = json['activeId'];
    if (records.isEmpty ||
        records.map((r) => r.id).toSet().length != records.length ||
        !records.any((r) => r.id == activeId)) {
      throw const FormatException('Invalid collection membership');
    }
    return PlantCollection(records, activeId as String);
  }
}
