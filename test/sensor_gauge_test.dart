import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/app.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/models/sensor_gauge.dart';
import 'package:plant_heart/services/local_repository.dart';
import 'package:plant_heart/widgets/sensor_status.dart';

SensorGauge reading(double value) => SensorGauge(
  id: 'moisture',
  label: 'Soil moisture',
  unit: '%',
  value: value,
  minimum: 0,
  maximum: 100,
  idealMinimum: 30,
  idealMaximum: 65,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'five zones classify a reading with a continuously advancing pointer',
    () {
      final values = [0.0, 20.0, 48.0, 75.0, 100.0];
      final gauges = values.map(reading).toList();
      expect(gauges.map((g) => g.zone), CareZone.values);
      for (var i = 1; i < gauges.length; i++) {
        expect(
          gauges[i].pointerFraction,
          greaterThan(gauges[i - 1].pointerFraction),
        );
      }
      expect(gauges.first.pointerFraction, 0);
      expect(gauges.last.pointerFraction, 1);
    },
  );
  test('ideal endpoints remain inclusive; nearby readings are outside', () {
    expect(reading(29.99).zone, CareZone.low);
    expect(reading(30).zone, CareZone.ideal);
    expect(reading(65).zone, CareZone.ideal);
    expect(reading(65.01).zone, CareZone.high);
    expect(reading(14.99).zone, CareZone.veryLow);
    expect(reading(15).zone, CareZone.low);
    expect(reading(82.5).zone, CareZone.veryHigh);
    expect(reading(30).pointerFraction, closeTo(.4, .0001));
    expect(reading(65).pointerFraction, closeTo(.6, .0001));
  });
  test(
    'all species produce ordered ranges; changing species changes the gauge',
    () {
      final d = PlantData()..sensors = const SensorReading(moisture: 25);
      expect(sensorGauges(d).first.zone, CareZone.low);
      d.species = 'snake';
      expect(sensorGauges(d).first.zone, CareZone.ideal);
      for (final profile in plantProfiles) {
        d.species = profile.id;
        for (final gauge in sensorGauges(d)) {
          for (var i = 1; i < gauge.boundaries.length; i++) {
            expect(gauge.boundaries[i], greaterThan(gauge.boundaries[i - 1]));
          }
          expect(gauge.pointerFraction, inInclusiveRange(0, 1));
          expect(gauge.accessibleDescription, contains(gauge.reading));
        }
      }
    },
  );
  test('extreme readings clamp the pointer and values keep units', () {
    expect(reading(-100).pointerFraction, 0);
    expect(reading(1000).pointerFraction, 1);
    final gauges = sensorGauges(PlantData());
    expect(gauges.map((g) => g.reading), [
      '48%',
      '4500 lux',
      '24°C',
      '60%',
      '6.5',
    ]);
    expect(gauges.first.target, '30–65%');
    expect(gauges.last.target, '6–7');
    expect(
      sensorGauges(PlantData()..species = 'snake').last.rangeDetails,
      contains('2.75'),
    );
    expect(reading(20.00000001).reading, '20%');
  });
  testWidgets('Home stacks five readings with details and navigation to Lab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final c = PlantController(
      LocalRepository(await SharedPreferences.getInstance()),
      PlantData()
        ..onboarded = true
        ..reducedMotion = true,
    );
    tester.view.physicalSize = const Size(440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PlantHeartApp(controller: c));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Plant conditions'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final y = <double>[];
    for (final id in ['moisture', 'light', 'temperature', 'humidity', 'ph']) {
      final card = find.byKey(ValueKey('gauge-$id'));
      await tester.scrollUntilVisible(
        card,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;
      y.add(tester.getTopLeft(card).dy + scroll);
      if (id == 'moisture') {
        await tester.tap(find.byTooltip('Soil moisture range details'));
        await tester.pumpAndSettle();
        expect(find.text('Soil moisture ranges'), findsOneWidget);
        expect(find.textContaining('30–65% (inclusive)'), findsOneWidget);
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
      }
    }
    for (var i = 1; i < y.length; i++) {
      expect(y[i], greaterThan(y[i - 1]));
    }
    await tester.scrollUntilVisible(
      find.text('Change readings in Lab'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Change readings in Lab').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Change readings in Lab').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('A tiny plant lab.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'status cards remain readable at narrow width with large text and extreme readings',
    (tester) async {
      final data = PlantData()
        ..sensors = const SensorReading(
          moisture: 0,
          light: 30000,
          temperature: 50,
          humidity: 100,
          ph: 14,
        );
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PlantConditions(data: data, openLab: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('gauge-ph')));
      await tester.pumpAndSettle();
      expect(find.byType(SensorStatusCard), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
  );
}
