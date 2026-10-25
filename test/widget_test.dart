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
    c = PlantController(
      LocalRepository(await SharedPreferences.getInstance()),
      PlantData()..reducedMotion = true,
      now: () => DateTime(2026, 10, 25, 10),
    );
  });
  tearDown(() => c.dispose());
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
    await tester.pumpAndSettle();
  }

  Future<void> closeTool(WidgetTester tester) async {
    if (find.byTooltip('Close test window').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Close test window'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> nav(WidgetTester tester, String label) async {
    await closeTool(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, [
    double delta = 200,
  ]) async {
    final dialogLists = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(ListView),
    );
    final list = dialogLists.evaluate().isNotEmpty
        ? dialogLists.first
        : find.byType(ListView).first;
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tool(WidgetTester tester, String title) async {
    await nav(tester, 'Home');
    await nav(tester, 'More');
    await reveal(tester, find.text(title));
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close test window'), findsOneWidget);
  }

  testWidgets('first run saves profile and does not repeat after reload', (
    tester,
  ) async {
    await start(tester, onboarded: false);
    expect(find.text('Meet your new\ngreen friend.'), findsOneWidget);
    await reveal(tester, find.text('Let’s grow together'));
    await tester.tap(find.text('Let’s grow together'));
    await tester.pumpAndSettle();
    expect(c.data.onboarded, isTrue);
    final loaded = await c.repository.load();
    expect(loaded.warning, isNull);
    final restarted = PlantController(
      c.repository,
      loaded.data,
      collection: loaded.collection,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(PlantHeartApp(controller: restarted));
    await tester.pumpAndSettle();
    expect(find.text('Meet your new\ngreen friend.'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    restarted.dispose();
  });
  testWidgets(
    'product navigation excludes test tools; popup inputs feed care and memoir',
    (tester) async {
      await start(tester);
      final bar = find.byType(NavigationBar);
      for (final label in ['Home', 'Community', 'Memoir', 'Care', 'More']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      for (final label in [
        'Lab',
        'Chat',
        'Sensor simulator',
        'Conversation simulator',
      ]) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsNothing,
        );
      }
      await tool(tester, 'Sensor simulator');
      await tester.tap(find.text('Dry Soil'));
      await tester.pumpAndSettle();
      expect(c.data.sensors.moisture, 12);
      await nav(tester, 'Home');
      expect(find.textContaining('Thirsty'), findsOneWidget);
      await tool(tester, 'Conversation simulator');
      await tester.enterText(
        find.byType(TextField),
        'Remember that I enjoy walks',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(c.data.memories.single.text, 'I enjoy walks');
      await nav(tester, 'Memoir');
      expect(find.text('I enjoy walks'), findsOneWidget);
      await tester.tap(find.text('Journey'));
      await tester.pumpAndSettle();
      expect(find.text('Milo’s growth journey'), findsOneWidget);
      await nav(tester, 'Care');
      expect(find.text('Soil moisture is low'), findsOneWidget);
      await nav(tester, 'Community');
      expect(find.text('Create local post'), findsOneWidget);
    },
  );
  testWidgets(
    'user tools use routes and all prototype tools use closable popups',
    (tester) async {
      await start(tester);
      await nav(tester, 'More');
      for (final title in ['Plant Library', 'Settings']) {
        await reveal(tester, find.text(title));
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.byType(BackButton), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      for (final title in [
        'Sensor simulator',
        'Conversation simulator',
        'Weather simulator',
        'Pixel Display Studio',
      ]) {
        await tool(tester, title);
        expect(find.byType(Dialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await closeTool(tester);
        expect(find.byType(NavigationBar), findsOneWidget);
      }
    },
  );
  testWidgets(
    'memoir creation, edit and cancelled/confirmed deletion persist',
    (tester) async {
      await start(tester);
      await nav(tester, 'Memoir');
      await tester.tap(find.text('Plant a memory'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Our first afternoon');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(c.data.memories.single.text, 'Our first afternoon');
      await reveal(tester, find.byTooltip('Edit memory'));
      await tester.tap(find.byTooltip('Edit memory'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Our first morning');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(c.data.memories.single.text, 'Our first morning');
      await tester.tap(find.byTooltip('Delete memory'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.data.memories, hasLength(1));
      await tester.tap(find.byTooltip('Delete memory'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(c.data.memories, isEmpty);
    },
  );
  testWidgets(
    'weather popup propagation, settings clear and reset controls work',
    (tester) async {
      await start(tester);
      await tool(tester, 'Weather simulator');
      await tester.tap(find.text('Heatwave'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Apply scenario to readings'));
      await tester.tap(find.text('Apply scenario to readings'));
      await tester.pumpAndSettle();
      expect(c.data.sensors.temperature, 38);
      await nav(tester, 'Home');
      await nav(tester, 'More');
      await reveal(tester, find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Larger text'));
      await tester.tap(find.text('Larger text'));
      await tester.pumpAndSettle();
      expect(c.data.largeText, isTrue);
      c.saveEntry('A memory to clear', memory: true);
      await tester.pump();
      await reveal(tester, find.text('Clear Memory Garden'));
      await tester.tap(find.text('Clear Memory Garden'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(c.data.memories, isEmpty);
      await reveal(tester, find.text('Reset all demo data'));
      await tester.tap(find.text('Reset all demo data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.data.onboarded, isTrue);
      await tester.tap(find.text('Reset all demo data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(c.data.onboarded, isFalse);
      expect(find.text('Meet your new\ngreen friend.'), findsOneWidget);
      expect((await c.repository.load()).data.memories, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('large text and narrow product navigation avoids overflow', (
    tester,
  ) async {
    c.data.largeText = true;
    await start(tester, size: const Size(360, 740));
    for (final label in ['Community', 'Memoir', 'Care', 'More', 'Home']) {
      await nav(tester, label);
      expect(tester.takeException(), isNull);
    }
    await tool(tester, 'Conversation simulator');
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(c.data.messages, hasLength(2));
    expect(tester.takeException(), isNull);
    await closeTool(tester);
    await tester.pump(const Duration(seconds: 9));
  });
  testWidgets(
    'semantic boundary survives product navigation and sensor popup',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await start(tester);
        final boundary = find.byKey(const ValueKey('main-content'));
        final id = tester.getSemantics(boundary).id;
        for (var pass = 0; pass < 2; pass++) {
          for (final label in ['Community', 'Memoir', 'Care', 'More', 'Home']) {
            await nav(tester, label);
            expect(tester.getSemantics(boundary).id, id);
          }
        }
        await tool(tester, 'Sensor simulator');
        await tester.tap(find.text('Dry Soil'));
        await tester.pumpAndSettle();
        final moisture = find.semantics.byValue('Soil moisture 12%');
        expect(moisture.evaluate(), hasLength(1));
        final data = moisture.evaluate().single.getSemanticsData();
        expect(data.increasedValue, isNot(data.value));
        expect(data.decreasedValue, isNot(data.value));
        await closeTool(tester);
        expect(tester.getSemantics(boundary).id, id);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
