import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/app.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/features/home.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/services/local_repository.dart';
import 'package:plant_heart/widgets/compact_sensor_status.dart';
import 'package:plant_heart/widgets/milo.dart';

void main() {
  late PlantController c;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = PlantController(
      LocalRepository(await SharedPreferences.getInstance()),
      PlantData()
        ..onboarded = true
        ..reducedMotion = true
        ..sensors = const SensorReading(moisture: 12),
    );
  });
  tearDown(() => c.dispose());
  testWidgets(
    'standard phone and Windows sizes show all readings with no Home scrollable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [
        const Size(390, 844),
        const Size(360, 740),
        const Size(440, 900),
        const Size(480, 960),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(PlantHeartApp(controller: c));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(HomePage),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        expect(find.byType(CompactSensorStatus), findsNWidgets(5));
        for (final id in [
          'moisture',
          'light',
          'temperature',
          'humidity',
          'ph',
        ]) {
          final row = find.byKey(ValueKey('compact-$id'));
          expect(row.hitTestable(), findsOneWidget);
          expect(
            tester.getBottomLeft(row).dy,
            lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy),
          );
        }
        expect(tester.takeException(), isNull);
      }
      c.data.largeText = true;
      await tester.pumpWidget(PlantHeartApp(controller: c));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(HomePage),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'add dialog, arrows and plant art switch real independent plants',
    (tester) async {
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(PlantHeartApp(controller: c));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Next plant',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Add plant'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fern');
      await tester.tap(find.text('Golden Pothos').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Snake Plant').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add plant'));
      await tester.pumpAndSettle();
      expect(c.plants.length, 2);
      expect(find.text('Fern'), findsOneWidget);
      expect(tester.widget<Milo>(find.byType(Milo)).species, 'snake');
      expect(c.data.messages, isEmpty);
      await tester.tap(find.byTooltip('Previous plant'));
      await tester.pumpAndSettle();
      expect(find.text('Milo'), findsOneWidget);
      expect(c.data.sensors.moisture, 12);
      expect(tester.widget<Milo>(find.byType(Milo)).species, 'pothos');
      await tester.tap(find.byTooltip('Next plant'));
      await tester.pumpAndSettle();
      expect(find.text('Fern'), findsOneWidget);
      expect(c.data.sensors.moisture, 27.5);
      expect(find.byType(CompactSensorStatus), findsNWidgets(5));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'extreme text scaling retains accessible controls without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      c.data.largeText = true;
      await tester.pumpWidget(PlantHeartApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byType(CompactSensorStatus), findsNWidgets(5));
      expect(find.byTooltip('Daily care check'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'plant switch slides and fades, then releases the outgoing plant',
    (tester) async {
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(PlantHeartApp(controller: c));
      await tester.pumpAndSettle();
      c.addPlant('Fern', 'snake', 'Gentle');
      await tester.pumpAndSettle();
      c.change(() => c.data.reducedMotion = false);
      await tester.pump();
      await tester.tap(find.byTooltip('Previous plant'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byType(Milo), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Milo), findsOneWidget);
      expect(tester.widget<Milo>(find.byType(Milo)).name, 'Milo');
      expect(c.data.sensors.moisture, 12);
      c.change(() => c.data.reducedMotion = true);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
