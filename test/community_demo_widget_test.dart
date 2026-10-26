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
      PlantData()
        ..onboarded = true
        ..reducedMotion = true,
    );
  });
  tearDown(() => c.dispose());
  Future<void> start(
    WidgetTester t, [
    Size size = const Size(480, 1100),
  ]) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(PlantHeartApp(controller: c));
    await t.pumpAndSettle();
  }

  Future<void> nav(WidgetTester t, String name) async {
    await t.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(name),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester t, Finder target) async {
    final s = find.byType(Scrollable).first;
    t.state<ScrollableState>(s).position.jumpTo(0);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(target, 240, scrollable: s);
    await t.ensureVisible(target);
    await t.pumpAndSettle();
  }

  testWidgets(
    'nearby map filters, pin selection and shared status/journal work',
    (t) async {
      await start(t);
      await nav(t, 'Community');
      expect(find.text('3 PlantHearts found'), findsOneWidget);
      await t.tap(find.byTooltip('Pip, 386 m, Care check'));
      await t.pumpAndSettle();
      await reveal(t, find.text('View shared journal'));
      await t.tap(find.text('View shared journal'));
      await t.pumpAndSettle();
      expect(find.text('Pip’s shared journal'), findsOneWidget);
      expect(find.text('Shared plant status'), findsOneWidget);
      await reveal(t, find.text('A dry afternoon'));
      expect(find.text('A dry afternoon'), findsOneWidget);
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await reveal(t, find.byType(TextField));
      await t.enterText(find.byType(TextField), 'Robin');
      await t.pumpAndSettle();
      await reveal(t, find.text('0 PlantHearts found'));
      expect(find.text('0 PlantHearts found'), findsOneWidget);
      await reveal(t, find.text('2 km'));
      await t.tap(find.text('2 km'));
      await t.pumpAndSettle();
      await reveal(t, find.text('1 PlantHeart found'));
      expect(find.text('1 PlantHeart found'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('plant talk advances without typing and stops on navigation', (
    t,
  ) async {
    await start(t);
    await nav(t, 'Community');
    await t.tap(find.text('Plant talk'));
    await t.pumpAndSettle();
    await reveal(t, find.text('Start automatic plant talk'));
    await t.tap(find.text('Start automatic plant talk'));
    await t.pump();
    expect(c.data.plantExchanges, hasLength(1));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 1300));
    }
    expect(c.data.plantExchanges, hasLength(2));
    await t.tap(find.text('Feed'));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 30));
    expect(c.data.plantExchanges, hasLength(2));
    expect(c.data.messages, isEmpty);
    expect(c.data.checkInDays, isEmpty);
    await t.tap(find.text('Plant talk'));
    await t.pumpAndSettle();
    await reveal(t, find.text('Start automatic plant talk'));
    await t.tap(find.text('Start automatic plant talk'));
    await t.pump();
    expect(c.data.plantExchanges, hasLength(3));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 30));
    expect(c.data.plantExchanges, hasLength(3));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(find.text('Start automatic plant talk'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'demo memoir adds sample moments and prepares a saved film entry',
    (t) async {
      await start(t);
      await nav(t, 'Memoir');
      await reveal(t, find.text('Add demo growth story'));
      await t.tap(find.text('Add demo growth story'));
      await t.pumpAndSettle();
      expect(c.data.demoStoryAt, isNotNull);
      await reveal(t, find.text('Films'));
      await t.tap(find.text('Films'));
      await t.pumpAndSettle();
      await reveal(t, find.text('Create demo film'));
      await t.tap(find.text('Create demo film'));
      await t.pumpAndSettle();
      expect(c.data.demoMovieAt, isNotNull);
      await reveal(t, find.text('Watch bloom film'));
      expect(find.text('Watch bloom film'), findsOneWidget);
      await reveal(t, find.text('Memories'));
      await t.tap(find.text('Memories'));
      await t.pumpAndSettle();
      await reveal(t, find.text('Our first bloom'));
      expect(find.text('Our first bloom'), findsOneWidget);
      expect(c.data.memories, isEmpty);
      expect(c.data.milestones, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('nearby and plant talk support narrow larger text', (t) async {
    c.data.largeText = true;
    await start(t, const Size(360, 740));
    await nav(t, 'Community');
    expect(t.takeException(), isNull);
    await t.tap(find.text('Plant talk'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await nav(t, 'Memoir');
    expect(t.takeException(), isNull);
  });
}
