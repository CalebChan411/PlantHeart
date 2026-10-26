class PlantLine {
  final String speaker, text;
  const PlantLine(this.speaker, this.text);
  Map<String, dynamic> toJson() => {'speaker': speaker, 'text': text};
  factory PlantLine.fromJson(Map<String, dynamic> j) =>
      PlantLine(j['speaker'] as String, j['text'] as String);
}

/// A local exchange separate from the owner's private conversation.
class PlantExchange {
  final String id, neighbourId, observation;
  final DateTime at;
  final List<PlantLine> lines;
  const PlantExchange({
    required this.id,
    required this.neighbourId,
    required this.observation,
    required this.at,
    required this.lines,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'neighbourId': neighbourId,
    'observation': observation,
    'at': at.toIso8601String(),
    'lines': lines.map((e) => e.toJson()).toList(),
  };
  factory PlantExchange.fromJson(Map<String, dynamic> j) => PlantExchange(
    id: j['id'] as String,
    neighbourId: j['neighbourId'] as String,
    observation: j['observation'] as String,
    at: DateTime.parse(j['at'] as String),
    lines: (j['lines'] as List)
        .map((v) => PlantLine.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList(),
  );
}
