import 'plant_data.dart';

enum CareZone {
  veryLow('Very low'),
  low('Low'),
  ideal('Ideal'),
  high('High'),
  veryHigh('Very high');

  final String label;
  const CareZone(this.label);
}

/// An ordinal five-zone display. The ideal interval comes directly from the
/// active profile, matching CareEngine (both endpoints included). Outer zones
/// split the remaining demo range in half; they are not scientific severity.
class SensorGauge {
  final String id, label, unit;
  final double value, minimum, maximum, idealMinimum, idealMaximum;
  const SensorGauge({
    required this.id,
    required this.label,
    required this.unit,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.idealMinimum,
    required this.idealMaximum,
  });
  double get lowBoundary => (minimum + idealMinimum) / 2;
  double get highBoundary => (idealMaximum + maximum) / 2;
  CareZone get zone {
    if (value < lowBoundary) return CareZone.veryLow;
    if (value < idealMinimum) return CareZone.low;
    if (value <= idealMaximum) return CareZone.ideal;
    if (value < highBoundary) return CareZone.high;
    return CareZone.veryHigh;
  }

  List<double> get boundaries => [
    minimum,
    lowBoundary,
    idealMinimum,
    idealMaximum,
    highBoundary,
    maximum,
  ];
  double get pointerFraction {
    final edges = boundaries;
    final index = zone.index;
    final width = edges[index + 1] - edges[index];
    final position = width <= 0
        ? .5
        : ((value - edges[index]) / width).clamp(0.0, 1.0);
    return (index + position) / 5;
  }

  String number(double number) {
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String formatted(double number) =>
      '${this.number(number)}${unit == 'lux' ? ' ' : ''}$unit';
  String get reading => formatted(value);
  String get target => '${number(idealMinimum)}–${formatted(idealMaximum)}';
  String get accessibleDescription =>
      '$label: $reading. ${zone.label}. Ideal range $target. Simulated reading.';
  String get rangeDetails =>
      '${CareZone.veryLow.label}: below ${formatted(lowBoundary)}\n'
      '${CareZone.low.label}: ${formatted(lowBoundary)} to below ${formatted(idealMinimum)}\n'
      '${CareZone.ideal.label}: $target (inclusive)\n'
      '${CareZone.high.label}: above ${formatted(idealMaximum)} to below ${formatted(highBoundary)}\n'
      '${CareZone.veryHigh.label}: ${formatted(highBoundary)} and above';
}

List<SensorGauge> sensorGauges(PlantData data) {
  final s = data.sensors, p = data.profile;
  return [
    SensorGauge(
      id: 'moisture',
      label: 'Soil moisture',
      unit: '%',
      value: s.moisture,
      minimum: 0,
      maximum: 100,
      idealMinimum: p.minMoisture,
      idealMaximum: p.maxMoisture,
    ),
    SensorGauge(
      id: 'light',
      label: 'Light intensity',
      unit: 'lux',
      value: s.light,
      minimum: 0,
      maximum: 30000,
      idealMinimum: p.minLight,
      idealMaximum: p.maxLight,
    ),
    SensorGauge(
      id: 'temperature',
      label: 'Temperature',
      unit: '°C',
      value: s.temperature,
      minimum: 0,
      maximum: 50,
      idealMinimum: p.minTemperature,
      idealMaximum: p.maxTemperature,
    ),
    SensorGauge(
      id: 'humidity',
      label: 'Air humidity',
      unit: '%',
      value: s.humidity,
      minimum: 0,
      maximum: 100,
      idealMinimum: p.minHumidity,
      idealMaximum: p.maxHumidity,
    ),
    SensorGauge(
      id: 'ph',
      label: 'Soil pH',
      unit: '',
      value: s.ph,
      minimum: 0,
      maximum: 14,
      idealMinimum: p.minPh,
      idealMaximum: p.maxPh,
    ),
  ];
}
