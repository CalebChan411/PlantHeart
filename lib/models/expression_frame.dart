import '../services/engines.dart';
import 'plant_data.dart';

enum PixelExpression {
  happy(
    'Happy',
    'Healthy conditions',
    'Everything feels balanced. A big smile and a cheeky wink.',
  ),
  calm(
    'Calm',
    'Comfortable / resting',
    'A quiet, neutral face. There is no urgent care alert.',
  ),
  thirsty(
    'Thirsty',
    'Dry soil',
    'Drooping eyes and a little blue drop: check the soil.',
  ),
  sleepy(
    'Sleepy',
    'Low light',
    'Closed eyes and a drifting Z: a dim-day simulation.',
  ),
  hot(
    'Too warm',
    'Hot day',
    'A worried mouth and a sweat drop: check temperature.',
  ),
  lonely(
    'Missing you',
    'No recent interaction',
    'A small frown and a tear: a fictional companion cue.',
  ),
  curious('Curious', 'A new interaction', 'Wide eyes and a small round mouth.'),
  loved(
    'Encouraged',
    'After a care check',
    'Happy eyes and little hearts. A preview of positive feedback.',
  );

  final String title, scenario, description;
  const PixelExpression(this.title, this.scenario, this.description);
}

/// Display-only payload; it never contains chat, memories or device commands.
class ExpressionFrame {
  final PixelExpression expression;
  final String name, source;
  final bool monochrome, reducedMotion;
  const ExpressionFrame({
    required this.expression,
    this.name = 'Milo',
    this.source = 'Scenario preview',
    this.monochrome = false,
    this.reducedMotion = false,
  });
  Map<String, dynamic> toJson() => {
    'version': 1,
    'expression': expression.name,
    'name': name,
    'source': source,
    'monochrome': monochrome,
    'reducedMotion': reducedMotion,
  };
  factory ExpressionFrame.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported display frame');
    }
    return ExpressionFrame(
      expression: PixelExpression.values.firstWhere(
        (e) => e.name == json['expression'],
      ),
      name: json['name'] as String,
      source: json['source'] as String,
      monochrome: json['monochrome'] == true,
      reducedMotion: json['reducedMotion'] == true,
    );
  }
}

/// Display cues are separate from the four-dimensional emotion model. A hot/low
/// light cue can therefore be shown without claiming to change the emotion rules.
PixelExpression expressionFor(PlantData data, PlantEmotion emotion) {
  if (data.sensors.temperature > data.profile.maxTemperature) {
    return PixelExpression.hot;
  }
  if (data.sensors.moisture < data.profile.minMoisture) {
    return PixelExpression.thirsty;
  }
  if (data.sensors.light < data.profile.minLight) return PixelExpression.sleepy;
  if (emotion.loneliness > 55) return PixelExpression.lonely;
  return emotion.mood == 'Thriving'
      ? PixelExpression.happy
      : PixelExpression.calm;
}

String? displaySource(List<String> arguments) {
  if (arguments.length == 2 && arguments.first == '--expression-screen') {
    return arguments[1];
  }
  return Uri.base.queryParameters['expressionScreen'];
}
