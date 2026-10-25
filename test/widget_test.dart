import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/app.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/services/local_repository.dart';

void main() {
  late PlantController c;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final data = PlantData()..reducedMotion = true;
    c = PlantController(
      LocalRepository(await SharedPreferences.getInstance()),
      data,
      now: () => DateTime(2026, 10, 24, 10),
    );
    await c.flush();
  });
  tearDown(() {
    c.dispose();
  });
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();
  Future<void> start(
    WidgetTester tester, {
    bool onboarded = true,
    Size size = const Size(440, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    c.data.onboarded = onboarded;
    await tester.pumpWidget(PlantHeartApp(controller: c));
    await settle(tester);
  }

  Future<void> nav(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await settle(tester);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
  }

  testWidgets(
    'first run saves profile and does not repeat after simulated reload',
    (tester) async {
      await start(tester, onboarded: false);
      expect(find.text('Meet your new\ngreen friend.'), findsOneWidget);
      await reveal(tester, find.text('Let’s grow together'));
      await tester.tap(find.text('Let’s grow together'));
      await settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(c.data.onboarded, isTrue);
      final loaded = await c.repository.load();
      expect(loaded.warning, isNull);
      expect(loaded.data.reducedMotion, isTrue);
      final restarted = PlantController(
        c.repository,
        loaded.data,
        collection: loaded.collection,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(PlantHeartApp(controller: restarted));
      await settle(tester);
      expect(find.text('Meet your new\ngreen friend.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      restarted.dispose();
    },
  );

  testWidgets('five destinations, preset, chat and explicit memory capture', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Milo'), findsOneWidget);
    await nav(tester, 'Lab');
    await tester.tap(find.text('Dry Soil'));
    await settle(tester);
    expect(c.data.sensors.moisture, 12);
    await nav(tester, 'Home');
    expect(find.textContaining('Thirsty'), findsOneWidget);
    await nav(tester, 'Chat');
    await tester.enterText(
      find.byType(TextField),
      'Remember that I enjoy walks',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await settle(tester);
    expect(c.data.memories.single.text, 'I enjoy walks');
    await nav(tester, 'Garden');
    expect(find.text('I enjoy walks'), findsOneWidget);
    await tester.tap(find.text('Journey'));
    await settle(tester);
    expect(find.text('Milo’s growth journey'), findsOneWidget);
    await nav(tester, 'More');
    expect(find.text('Care Guide'), findsOneWidget);
    expect(find.text('Weather'), findsOneWidget);
  });

  testWidgets('all detail modules open and back navigation works', (
    tester,
  ) async {
    await start(tester);
    await nav(tester, 'More');
    for (final title in [
      'Pixel Display Studio',
      'Care Guide',
      'Weather',
      'Community',
      'Plant Library',
      'Settings',
    ]) {
      await reveal(tester, find.text(title));
      await tester.tap(find.text(title));
      await settle(tester);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
    }
  });

  testWidgets(
    'memory add, edit and confirmed deletion interact with persistent state',
    (tester) async {
      await start(tester);
      await nav(tester, 'Garden');
      await tester.tap(find.text('Plant a memory'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Our first afternoon');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(c.data.memories.single.text, 'Our first afternoon');
      await reveal(tester, find.byTooltip('Edit memory'));
      await tester.tap(find.byTooltip('Edit memory'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Our first morning');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(c.data.memories.single.text, 'Our first morning');
      await tester.tap(find.byTooltip('Delete memory'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(c.data.memories, hasLength(1));
      await tester.tap(find.byTooltip('Delete memory'));
      await settle(tester);
      await tester.tap(find.text('Confirm'));
      await settle(tester);
      expect(c.data.memories, isEmpty);
    },
  );

  testWidgets(
    'weather apply and settings preferences, clear and reset controls work',
    (tester) async {
      await start(tester);
      await nav(tester, 'More');
      await tester.tap(find.text('Weather'));
      await settle(tester);
      await tester.tap(find.text('Heatwave'));
      await settle(tester);
      await reveal(tester, find.text('Apply scenario to Sensor Lab'));
      await tester.tap(find.text('Apply scenario to Sensor Lab'));
      await settle(tester);
      expect(c.data.sensors.temperature, 38);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      await reveal(tester, find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await settle(tester);
      await reveal(tester, find.text('Larger text'));
      await tester.tap(find.text('Larger text'));
      await settle(tester);
      expect(c.data.largeText, isTrue);
      c.saveEntry('A memory to clear', memory: true);
      await tester.pump();
      await reveal(tester, find.text('Clear Memory Garden'));
      await tester.tap(find.text('Clear Memory Garden'));
      await settle(tester);
      await tester.tap(find.text('Confirm'));
      await settle(tester);
      expect(c.data.memories, isEmpty);
      await reveal(tester, find.text('Reset all demo data'));
      await tester.tap(find.text('Reset all demo data'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(c.data.onboarded, isTrue);
      await tester.tap(find.text('Reset all demo data'));
      await settle(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(c.data.onboarded, isFalse);
      expect(find.text('Meet your new\ngreen friend.'), findsOneWidget);
      expect((await c.repository.load()).data.memories, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'large text and narrow viewport scroll without overflow across pages',
    (tester) async {
      c.data.largeText = true;
      await start(tester, size: const Size(360, 740));
      for (final title in ['Lab', 'Chat', 'Garden', 'More', 'Home']) {
        await nav(tester, title);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'semantic content boundary stays stable across navigation and saved updates',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await start(tester);
        final boundary = find.byKey(const ValueKey('main-content'));
        final id = tester.getSemantics(boundary).id;
        for (var pass = 0; pass < 3; pass++) {
          for (final tab in ['Lab', 'Chat', 'Garden', 'More', 'Home']) {
            await nav(tester, tab);
            expect(tester.getSemantics(boundary).id, id);
            if (tab == 'Lab') {
              await tester.tap(find.text('Dry Soil'));
              await settle(tester);
              final moisture = find.semantics.byValue('Soil moisture 12%');
              expect(moisture.evaluate(), hasLength(1));
              final data = moisture.evaluate().single.getSemanticsData();
              expect(data.increasedValue, isNot(data.value));
              expect(data.decreasedValue, isNot(data.value));
              expect(tester.getSemantics(boundary).id, id);
              await tester.tap(find.text('Healthy Conditions'));
              await settle(tester);
              expect(tester.getSemantics(boundary).id, id);
            }
            expect(tester.takeException(), isNull);
          }
        }
      } finally {
        semantics.dispose();
      }
    },
  );
}
