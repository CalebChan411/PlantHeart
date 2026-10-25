import '../../models/expression_frame.dart';

class DisplayHost {
  void publish(ExpressionFrame frame) {}
  Future<bool> open() async => false;
  Future<void> dispose() async {}
}

class ScreenFeed {
  ScreenFeed(String source);
  Future<ExpressionFrame?> read() async => null;
  void close() {}
}
