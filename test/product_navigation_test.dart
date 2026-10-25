import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/app.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/services/local_repository.dart';

void main() {
  testWidgets(
    'build flag controls prototype tools without removing product destinations',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final c = PlantController(
        LocalRepository(await SharedPreferences.getInstance()),
        PlantData()
          ..onboarded = true
          ..reducedMotion = true,
      );
      tester.view.physicalSize = const Size(440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(PlantHeartApp(controller: c));
      await tester.pumpAndSettle();
      final bar = find.byType(NavigationBar);
      for (final label in ['Home', 'Community', 'Memoir', 'Care', 'More']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: bar, matching: find.text('Chat')),
        findsNothing,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Lab')),
        findsNothing,
      );
      await tester.tap(find.descendant(of: bar, matching: find.text('More')));
      await tester.pumpAndSettle();
      expect(find.text('Plant Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      if (testingToolsEnabled) {
        expect(find.text('Prototype testing'), findsOneWidget);
      } else {
        for (final label in [
          'Prototype testing',
          'Conversation simulator',
          'Sensor simulator',
          'Weather simulator',
          'Pixel Display Studio',
        ]) {
          expect(find.text(label), findsNothing);
        }
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
