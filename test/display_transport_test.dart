import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_heart/models/expression_frame.dart';
import 'package:plant_heart/services/display/display_link_io.dart';

void main() {
  test(
    'local display transports frames, rejects wrong path and closes without editing app data',
    () async {
      Uri? endpoint;
      final host = DisplayHost(
        launcher: (uri) async {
          endpoint = uri;
        },
      );
      final client = HttpClient();
      ScreenFeed? receiver;
      try {
        host.publish(const ExpressionFrame(expression: PixelExpression.happy));
        expect(await host.open(), isTrue);
        expect(endpoint!.host, '127.0.0.1');
        receiver = ScreenFeed(endpoint.toString());
        expect((await receiver.read())!.expression, PixelExpression.happy);
        host.publish(
          const ExpressionFrame(
            expression: PixelExpression.thirsty,
            monochrome: true,
          ),
        );
        final next = await receiver.read();
        expect(next!.expression, PixelExpression.thirsty);
        expect(next.monochrome, isTrue);
        final request = await client.getUrl(
          endpoint!.replace(path: '/wrong-channel'),
        );
        final response = await request.close();
        expect(response.statusCode, 404);
        await response.drain<void>();
        expect(jsonEncode(next.toJson()), isNot(contains('memories')));
        expect(
          () => ScreenFeed('https://example.com/frame'),
          throwsFormatException,
        );
        expect(
          () => ScreenFeed('http://127.0.0.1:80@evil.test/frame'),
          throwsFormatException,
        );
      } finally {
        receiver?.close();
        client.close(force: true);
        await host.dispose();
      }
      expect(await host.open(), isFalse);
    },
  );
}
