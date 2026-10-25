import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/app.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/app/pixel_display_controller.dart';
import 'package:plant_heart/models/expression_frame.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/services/engines.dart';
import 'package:plant_heart/services/local_repository.dart';
import 'package:plant_heart/widgets/pixel_face.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlantController c;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    c = PlantController(
      LocalRepository(await SharedPreferences.getInstance()),
      PlantData()
        ..onboarded = true
        ..reducedMotion = true,
      now: () => DateTime(2026, 10, 25),
    );
  });
  tearDown(() => c.dispose());
  test(
    'display mapping prioritizes heat, dry soil and low light over companion cues',
    () async {
      expect(c.pixelDisplay.frame.expression, PixelExpression.happy);
      await c.preset('Dry Soil');
      expect(c.pixelDisplay.frame.expression, PixelExpression.thirsty);
      await c.preset('Low Light');
      expect(c.pixelDisplay.frame.expression, PixelExpression.sleepy);
      await c.weather('Heatwave', 'Hong Kong', apply: true);
      expect(c.pixelDisplay.frame.expression, PixelExpression.hot);
      await c.preset('Healthy Conditions');
      c.data.lastInteraction = DateTime(2026, 10, 10);
      expect(
        expressionFor(
          c.data,
          EmotionEngine().evaluate(c.data, DateTime(2026, 10, 25)),
        ),
        PixelExpression.lonely,
      );
    },
  );
  test(
    'manual expressions do not change sensors, rewards, memories or mood',
    () {
      final before = jsonEncode(c.data.toJson());
      c.pixelDisplay.select(PixelExpression.loved);
      c.pixelDisplay.setPauseMotion(true);
      expect(c.pixelDisplay.frame.expression, PixelExpression.loved);
      expect(c.pixelDisplay.frame.monochrome, isTrue);
      expect(jsonEncode(c.data.toJson()), before);
      c.pixelDisplay.setMode(PreviewMode.follow);
      expect(c.pixelDisplay.frame.expression, PixelExpression.happy);
    },
  );
  test(
    'display payload round trips all expressions and excludes personal records',
    () {
      for (final expression in PixelExpression.values) {
        final frame = ExpressionFrame(
          expression: expression,
          monochrome: true,
          reducedMotion: true,
        );
        expect(
          ExpressionFrame.fromJson(
            jsonDecode(jsonEncode(frame.toJson())) as Map<String, dynamic>,
          ).expression,
          expression,
        );
        expect(frame.toJson().keys, isNot(contains('messages')));
        expect(frame.toJson().keys, isNot(contains('memories')));
      }
      expect(
        () => ExpressionFrame.fromJson({'version': 2}),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'studio opens from More; eight scenarios, monochrome and tour work',
    (tester) async {
      tester.view.physicalSize = const Size(440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(PlantHeartApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('More'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Pixel Display Studio'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pixel Display Studio'));
      await tester.pumpAndSettle();
      Future<void> revealInStudio(Finder target, double delta) async {
        final list = find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(ListView),
            )
            .first;
        final scroll = find
            .descendant(of: list, matching: find.byType(Scrollable))
            .first;
        // Selecting a manual scene removes the tall follow-state explanation.
        // Start from the top so lazy children cannot move above the search.
        tester.state<ScrollableState>(scroll).position.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          target,
          delta.abs(),
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 12 && target.hitTestable().evaluate().isEmpty;
          i++
        ) {
          final dialog = tester.getRect(find.byType(Dialog));
          final dy = target.evaluate().isEmpty
              ? delta
              : tester.getCenter(target).dy < dialog.top
              ? -180.0
              : 180.0;
          await tester.drag(list, Offset(0, -dy));
          await tester.pumpAndSettle();
        }
        expect(target.hitTestable(), findsOneWidget);
      }

      final before = jsonEncode(c.data.toJson());
      for (final expression in PixelExpression.values) {
        await revealInStudio(find.text(expression.title), 180);
        await tester.tap(find.text(expression.title));
        await tester.pumpAndSettle();
        expect(c.pixelDisplay.frame.expression, expression);
      }
      expect(jsonEncode(c.data.toJson()), before);
      expect(c.pixelDisplay.frame.monochrome, isTrue);
      // Scroll back up to the mode selector.
      await revealInStudio(find.text('Auto preview'), -200);
      await tester.tap(find.text('Auto preview'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(c.pixelDisplay.frame.expression, PixelExpression.calm);
      c.pixelDisplay.setMode(PreviewMode.follow);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await revealInStudio(find.text('Compare all expressions'), -200);
      await tester.tap(find.text('Compare all expressions'));
      await tester.pumpAndSettle();
      expect(find.byType(PixelFace), findsNWidgets(8));
      expect(find.text('Expression sheet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'pixel faces render at narrow sizes with accessible descriptions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        for (final expression in PixelExpression.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: PixelFace(
                      frame: ExpressionFrame(
                        expression: expression,
                        reducedMotion: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            find.bySemanticsLabel(RegExp('Milo: ${expression.title}')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    },
  );
}
