import '../services/engines.dart';
import 'plant_data.dart';

enum PixelExpression {
  happy('Happy', 'Healthy conditions', 'A friendly wink and an open smile.'),
  calm('Calm', 'Comfortable / resting', 'Relaxed eyes and a quiet mouth.'),
  thirsty('Thirsty', 'Dry soil', 'Drooping eyes and an uneven worried mouth.'),
  sleepy('Sleepy', 'Low light', 'Closed eyes and a small yawn.'),
  hot('Too warm', 'Hot day', 'Tense eyebrows and a panting mouth.'),
  lonely(
    'Missing you',
    'No recent interaction',
    'Downcast eyes and a small frown.',
  ),
  curious('Curious', 'A new interaction', 'Wide eyes and a small round mouth.'),
  loved(
    'Encouraged',
    'After a care check',
    'Happy curved eyes and a broad smile.',
  );

  final String title, scenario, description;
  const PixelExpression(this.title, this.scenario, this.description);
}

enum InteractionPhase { idle, replying }

/// Version 2 carries only animation timing, never the actual conversation text.
/// Version-1 display frames can still be read, with idle animation defaults.
class ExpressionFrame {
  final PixelExpression expression;
  final String name, source;
  final bool monochrome, reducedMotion;
  final InteractionPhase interaction;
  final int replyId, replyEndsAtMs;
  const ExpressionFrame({
    required this.expression,
    this.name = 'Milo',
    this.source = 'Scenario preview',
    this.monochrome = true,
    this.reducedMotion = false,
    this.interaction = InteractionPhase.idle,
    this.replyId = 0,
    this.replyEndsAtMs = 0,
  });
  bool replyingAt(DateTime time) =>
      interaction == InteractionPhase.replying &&
      time.millisecondsSinceEpoch < replyEndsAtMs;
  Map<String, dynamic> toJson() => {
    'version': 2,
    'expression': expression.name,
    'name': name,
    'source': source,
    'monochrome': true,
    'reducedMotion': reducedMotion,
    'interaction': interaction.name,
    'replyId': replyId,
    'replyEndsAtMs': replyEndsAtMs,
  };
  factory ExpressionFrame.fromJson(Map<String, dynamic> json) {
    if (![1, 2].contains(json['version']) ||
        json['name'] is! String ||
        json['source'] is! String) {
      throw const FormatException('Unsupported display frame');
    }
    final expression = PixelExpression.values
        .where((e) => e.name == json['expression'])
        .firstOrNull;
    if (expression == null) {
      throw const FormatException('Invalid display expression');
    }
    final phase =
        InteractionPhase.values
            .where((p) => p.name == json['interaction'])
            .firstOrNull ??
        InteractionPhase.idle;
    return ExpressionFrame(
      expression: expression,
      name: json['name'] as String,
      source: json['source'] as String,
      reducedMotion: json['reducedMotion'] == true,
      interaction: phase,
      replyId: json['replyId'] is int ? json['replyId'] as int : 0,
      replyEndsAtMs: json['replyEndsAtMs'] is int
          ? json['replyEndsAtMs'] as int
          : 0,
    );
  }
}

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
