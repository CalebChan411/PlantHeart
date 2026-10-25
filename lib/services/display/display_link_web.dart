import 'dart:convert';
import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import '../../models/expression_frame.dart';

@JS('window.open')
external JSObject? _openWindow(
  JSString url,
  JSString target,
  JSString features,
);
@JS('localStorage.setItem')
external void _write(JSString key, JSString value);
@JS('localStorage.getItem')
external JSString? _read(JSString key);
@JS('localStorage.removeItem')
external void _remove(JSString key);

class DisplayHost {
  final _key =
      'plant-heart-display-${List.generate(12, (_) => Random.secure().nextInt(256).toRadixString(16)).join()}';
  ExpressionFrame? _frame;
  Timer? _heartbeat;
  void _send() {
    if (_frame != null) {
      _write(
        _key.toJS,
        jsonEncode({
          'frame': _frame!.toJson(),
          'at': DateTime.now().millisecondsSinceEpoch,
        }).toJS,
      );
    }
  }

  void publish(ExpressionFrame frame) {
    _frame = frame;
    // Browser storage is only a temporary bridge for expression metadata.
    _send();
    _heartbeat ??= Timer.periodic(const Duration(seconds: 1), (_) {
      try {
        _send();
      } catch (_) {
        /* Receiver reports a stale link. */
      }
    });
  }

  Future<bool> open() async {
    if (_frame == null) return false;
    final url = Uri.base.replace(
      queryParameters: {'expressionScreen': _key},
      fragment: '',
    );
    return _openWindow(
          url.toString().toJS,
          _key.toJS,
          'popup,width=620,height=680'.toJS,
        ) !=
        null;
  }

  Future<void> dispose() async {
    _heartbeat?.cancel();
    try {
      _remove(_key.toJS);
    } catch (_) {
      /* Stale frames expire in the receiver. */
    }
  }
}

class ScreenFeed {
  final String source;
  ScreenFeed(this.source) {
    if (!source.startsWith('plant-heart-display-')) {
      throw const FormatException('Invalid local display channel');
    }
  }
  Future<ExpressionFrame?> read() async {
    final raw = _read(source.toJS)?.toDart;
    if (raw == null) return null;
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (DateTime.now().millisecondsSinceEpoch - (json['at'] as int) > 5000) {
      return null;
    }
    return ExpressionFrame.fromJson(
      Map<String, dynamic>.from(json['frame'] as Map),
    );
  }

  void close() {}
}
