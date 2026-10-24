import '../models/plant_data.dart';

class CareTip {
  final String title, reason, action;
  final int priority;
  const CareTip(this.title, this.reason, this.action, this.priority);
}

class CareEngine {
  List<CareTip> evaluate(SensorReading s, PlantProfile p) {
    final tips = <CareTip>[];
    void range(
      double v,
      double min,
      double max,
      String label,
      String unit,
      String low,
      String high,
      int priority,
    ) {
      if (v < min || v > max) {
        tips.add(
          CareTip(
            v < min ? '$label is low' : '$label is high',
            '${v.toStringAsFixed(label == 'Soil pH' ? 1 : 0)}$unit; demo range ${min.toStringAsFixed(label == 'Soil pH' ? 1 : 0)}–${max.toStringAsFixed(label == 'Soil pH' ? 1 : 0)}$unit for ${p.name}.',
            v < min ? low : high,
            priority,
          ),
        );
      }
    }

    range(
      s.moisture,
      p.minMoisture,
      p.maxMoisture,
      'Soil moisture',
      '%',
      'Check the topsoil, then water gently if dry.',
      'Pause watering and check drainage.',
      5,
    );
    range(
      s.temperature,
      p.minTemperature,
      p.maxTemperature,
      'Temperature',
      '°C',
      'Move away from cold drafts.',
      'Move to a cooler, shaded spot.',
      4,
    );
    range(
      s.light,
      p.minLight,
      p.maxLight,
      'Light',
      ' lux',
      'Move closer to bright, indirect light.',
      'Filter harsh sunlight with a curtain.',
      3,
    );
    range(
      s.humidity,
      p.minHumidity,
      p.maxHumidity,
      'Air humidity',
      '%',
      'Try a pebble tray nearby; keep roots out of standing water.',
      'Improve gentle air circulation.',
      2,
    );
    range(
      s.ph,
      p.minPh,
      p.maxPh,
      'Soil pH',
      '',
      'Recheck pH before changing the growing medium.',
      'Recheck pH before changing the growing medium.',
      1,
    );
    tips.sort((a, b) => b.priority.compareTo(a.priority));
    if (tips.isEmpty) {
      tips.add(
        const CareTip(
          'A lovely balance',
          'All five readings are inside this species’ illustrative ranges.',
          'Keep your routine gentle. Check the soil before watering.',
          0,
        ),
      );
    }
    return tips;
  }
}

class PlantEmotion {
  final int comfort, vitality, attachment, loneliness;
  final String mood, explanation;
  const PlantEmotion(
    this.comfort,
    this.vitality,
    this.attachment,
    this.loneliness,
    this.mood,
    this.explanation,
  );
}

class EmotionEngine {
  PlantEmotion evaluate(PlantData d, DateTime now) {
    final warnings = CareEngine()
        .evaluate(d.sensors, d.profile)
        .where((t) => t.priority > 0)
        .length;
    final comfort = (100 - warnings * 18).clamp(0, 100);
    final vitality =
        (100 -
                warnings * 12 -
                (d.sensors.temperature > d.profile.maxTemperature + 5 ? 15 : 0))
            .clamp(0, 100);
    final days = d.lastInteraction == null
        ? 0
        : now.difference(d.lastInteraction!).inHours ~/ 24;
    final loneliness = d.lastInteraction == null
        ? 25
        : (days * 15).clamp(0, 100);
    final attachment = (20 + d.memories.length * 4 + d.checkInDays.length * 5)
        .clamp(0, 100);
    final mood = d.sensors.moisture < d.profile.minMoisture
        ? 'Thirsty'
        : vitality < 65
        ? 'Sleepy'
        : loneliness > 55
        ? 'Missing you'
        : comfort >= 90
        ? 'Thriving'
        : 'Calm';
    return PlantEmotion(
      comfort,
      vitality,
      attachment,
      loneliness,
      mood,
      '$warnings readings outside demo ranges. ${d.memories.length} shared memories and ${d.checkInDays.length} care days build attachment. '
      'Time since your last interaction influences loneliness. These are fictional companion metrics.',
    );
  }
}

class SensorService {
  static const presets = {
    'Healthy Conditions': SensorReading(),
    'Dry Soil': SensorReading(moisture: 12),
    'Low Light': SensorReading(light: 180),
    'Hot Day': SensorReading(moisture: 25, temperature: 38, humidity: 32),
  };
  SensorReading healthy(PlantProfile p) => SensorReading(
    moisture: (p.minMoisture + p.maxMoisture) / 2,
    light: (p.minLight + p.maxLight) / 2,
    temperature: (p.minTemperature + p.maxTemperature) / 2,
    humidity: (p.minHumidity + p.maxHumidity) / 2,
    ph: (p.minPh + p.maxPh) / 2,
  );
}

class WeatherScenario {
  final String name, rain, wind, uv, reminder;
  final SensorReading reading;
  const WeatherScenario(
    this.name,
    this.rain,
    this.wind,
    this.uv,
    this.reminder,
    this.reading,
  );
}

const weatherScenarios = [
  WeatherScenario(
    'Sunny',
    '0 mm',
    '12 km/h',
    '6 · high',
    'Filter strong afternoon sun; check soil before watering.',
    SensorReading(moisture: 42, light: 8000, temperature: 27, humidity: 58),
  ),
  WeatherScenario(
    'Rainy',
    '28 mm',
    '22 km/h',
    '2 · low',
    'Shelter outdoor pots and check drainage. Indoor plants still need light.',
    SensorReading(moisture: 78, light: 800, temperature: 23, humidity: 88),
  ),
  WeatherScenario(
    'Heatwave',
    '0 mm',
    '8 km/h',
    '10 · very high',
    'Move away from hot glass. Avoid watering by a calendar alone.',
    SensorReading(moisture: 20, light: 16000, temperature: 38, humidity: 35),
  ),
  WeatherScenario(
    'Cool & cloudy',
    '1 mm',
    '16 km/h',
    '1 · low',
    'Protect from cold drafts and allow soil to dry more slowly.',
    SensorReading(moisture: 50, light: 900, temperature: 14, humidity: 70),
  ),
];

class AgentReply {
  final String text;
  final String? memory;
  const AgentReply(this.text, [this.memory]);
}

class PlantAgent {
  AgentReply respond(String input, PlantData d, PlantEmotion emotion) {
    final text = input.trim();
    final lower = text.toLowerCase();
    final prefix = switch (d.personality) {
      'Playful' => 'Leaf high-five! ',
      'Thoughtful' => 'One small thought: ',
      _ => '',
    };
    if (RegExp(
      r'\b(suicide|suicidal|self.harm|kill myself|hurt myself|end my life)\b',
    ).hasMatch(lower)) {
      return const AgentReply(
        'I’m glad you told me. You deserve support from a real person. '
        'If you might hurt yourself or are in immediate danger, call your local emergency number (999 in Hong Kong) now. '
        'Please reach out to someone you trust or a qualified professional. I’m a local plant simulator, not professional help.',
      );
    }
    if (lower == 'remember' || lower == 'remember that') {
      return const AgentReply(
        'What would you like me to remember? Try “Remember that I love rainy mornings.”',
      );
    }
    final capture = RegExp(
      r'^remember(?:\s+that)?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (capture != null) {
      return AgentReply(
        'I’ve saved this in our Memory Garden: “${capture[1]}”',
        capture[1]!.trim(),
      );
    }
    if (RegExp(r'\b(memory|memories|recall|remember)\b').hasMatch(lower)) {
      return AgentReply(
        d.memories.isEmpty
            ? 'Our Memory Garden is waiting for its first seed. Tell me “Remember that…” to save something.'
            : 'A memory I treasure: “${d.memories.last.text}”. You can edit it in Garden.',
      );
    }
    if (RegExp(
      r'\b(water|care|light|soil|temperature|humidity|ph)\b',
    ).hasMatch(lower)) {
      final tip = CareEngine().evaluate(d.sensors, d.profile).first;
      return AgentReply(
        '$prefix As your ${d.profile.name}, here’s my current care check: '
        '${tip.title}. ${tip.reason} ${tip.action} These are illustrative simulator rules.',
      );
    }
    if (RegExp(
      r'\b(sad|lonely|stress|stressed|anxious|overwhelmed)\b',
    ).hasMatch(lower)) {
      return AgentReply(
        '${prefix}I’m here for a quiet moment with you. Try one slow breath and name one small thing you can do next. '
        'Talking to someone you trust can help too. I can offer companionship, not medical care.',
      );
    }
    if (RegExp(r'\b(hi|hello|hey|morning)\b').hasMatch(lower)) {
      return AgentReply(
        '${prefix}Hello, I’m ${d.name}, your ${d.personality.toLowerCase()} ${d.profile.name} friend. '
        'I’m feeling ${emotion.mood.toLowerCase()} in our little simulation. How is your day growing?',
      );
    }
    if (RegExp(r'\b(feel|feeling|today|check|mood)\b').hasMatch(lower)) {
      return AgentReply(
        '${prefix}I’m ${emotion.mood.toLowerCase()} today. Soil moisture is ${d.sensors.moisture.round()}% '
        'and my room is ${d.sensors.temperature.round()}°C. ${CareEngine().evaluate(d.sensors, d.profile).first.action}',
      );
    }
    return AgentReply(
      '${prefix}Thanks for sharing a moment with ${d.name}. I’m a local rule-based companion, '
      'so I may miss what you mean. Ask about care, how I feel, or tell me “Remember that…” to plant a memory.',
    );
  }
}
