import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_heart/app/plant_controller.dart';
import 'package:plant_heart/models/expression_frame.dart';
import 'package:plant_heart/models/plant_data.dart';
import 'package:plant_heart/services/local_repository.dart';
import 'package:plant_heart/widgets/pixel_face.dart';

Future<Uint8List> raster(ExpressionFrame frame, int tick) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  PixelFacePainter(frame, tick).paint(canvas, const Size(128, 96));
  final picture = recorder.endRecording();
  final image = await picture.toImage(128, 96);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('pixel painter preserves the surrounding tool background', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFFEDF2E7), BlendMode.src);
    canvas.save();
    canvas.translate(16, 16);
    const PixelFacePainter(
      ExpressionFrame(expression: PixelExpression.happy),
    ).paint(canvas, const Size(128, 96));
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(160, 128);
    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = raw!.buffer.asUint8List();
    for (final point in [const Offset(0, 0), const Offset(159, 127)]) {
      final i = (point.dy.toInt() * 160 + point.dx.toInt()) * 4;
      expect(bytes.sublist(i, i + 4), [237, 242, 231, 255]);
    }
    image.dispose();
    picture.dispose();
  });
  test(
    'all eight expressions are white facial pixels on black with no filled head',
    () async {
      for (final expression in PixelExpression.values) {
        final bytes = await raster(ExpressionFrame(expression: expression), 0);
        var lit = 0;
        for (var i = 0; i < bytes.length; i += 4) {
          expect(bytes[i], anyOf(0, 255));
          expect(bytes[i + 1], bytes[i]);
          expect(bytes[i + 2], bytes[i]);
          expect(bytes[i + 3], 255);
          if (bytes[i] == 255) lit++;
        }
        expect(lit, greaterThan(20));
        expect(lit, lessThan(128 * 96 * .25));
        expect(bytes[0], 0);
        expect(
          bytes[(48 * 128 + 64) * 4],
          0,
        ); // Empty space between eyes and mouth.
      }
    },
  );
  test(
    'reply opens and closes the mouth; reduced motion keeps a static pose',
    () async {
      final end = DateTime.now()
          .add(const Duration(minutes: 1))
          .millisecondsSinceEpoch;
      final frame = ExpressionFrame(
        expression: PixelExpression.happy,
        interaction: InteractionPhase.replying,
        replyId: 1,
        replyEndsAtMs: end,
      );
      expect(
        listEquals(await raster(frame, 0), await raster(frame, 2)),
        isFalse,
      );
      final still = ExpressionFrame(
        expression: PixelExpression.happy,
        reducedMotion: true,
        interaction: InteractionPhase.replying,
        replyId: 1,
        replyEndsAtMs: end,
      );
      expect(
        listEquals(await raster(still, 0), await raster(still, 2)),
        isTrue,
      );
    },
  );
  test('display frame compatibility, deadlines and privacy are explicit', () {
    final original = ExpressionFrame(
      expression: PixelExpression.curious,
      interaction: InteractionPhase.replying,
      replyId: 7,
      replyEndsAtMs: 5000,
    );
    final restored = ExpressionFrame.fromJson(original.toJson());
    expect(restored.replyId, 7);
    expect(
      restored.replyingAt(DateTime.fromMillisecondsSinceEpoch(4999)),
      isTrue,
    );
    expect(
      restored.replyingAt(DateTime.fromMillisecondsSinceEpoch(5000)),
      isFalse,
    );
    final legacy = ExpressionFrame.fromJson({
      'version': 1,
      'expression': 'happy',
      'name': 'Milo',
      'source': 'Legacy',
      'monochrome': false,
    });
    expect(legacy.monochrome, isTrue);
    expect(legacy.interaction, InteractionPhase.idle);
    expect(original.toJson().keys, isNot(contains('text')));
    expect(original.toJson().keys, isNot(contains('messages')));
    expect(
      () => ExpressionFrame.fromJson({'version': 99}),
      throwsFormatException,
    );
  });
  testWidgets(
    'each reply animates once, settles, replays without messages and cancels on plant switch',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final c = PlantController(
        LocalRepository(await SharedPreferences.getInstance()),
        PlantData()..onboarded = true,
      );
      await tester.pumpWidget(const SizedBox());
      try {
        c.send('Hello');
        await tester.pump();
        final first = c.pixelDisplay.frame;
        expect(first.interaction, InteractionPhase.replying);
        expect(first.replyId, 1);
        expect(c.data.messages.length, 2);
        await tester.pump(const Duration(seconds: 9));
        expect(c.pixelDisplay.frame.interaction, InteractionPhase.idle);
        c.pixelDisplay.playReply(c.data.messages.last.text);
        await tester.pump();
        expect(c.pixelDisplay.frame.replyId, 2);
        expect(c.data.messages.length, 2);
        c.addPlant('Fern', 'snake', 'Gentle');
        await tester.pump();
        expect(c.pixelDisplay.frame.interaction, InteractionPhase.idle);
        expect(c.pixelDisplay.frame.name, 'Fern');
        expect(c.data.messages, isEmpty);
      } finally {
        c.dispose();
      }
    },
  );
}
