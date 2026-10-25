import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../../models/expression_frame.dart';

/// Local software-window transport, not a hardware protocol or external server.
class DisplayHost {
  final Future<void> Function(Uri)? launcher;
  DisplayHost({this.launcher});
  HttpServer? _server;
  ExpressionFrame? _frame;
  bool _disposed = false;
  Future<bool>? _opening;
  final _token = List.generate(
    20,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  void publish(ExpressionFrame frame) {
    _frame = frame;
  }

  Future<bool> open() =>
      _opening ??= _open().whenComplete(() => _opening = null);
  Future<bool> _open() async {
    if (_disposed) return false;
    final server = _server ??= await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    if (_disposed) {
      await server.close(force: true);
      return false;
    }
    if (!_listening) {
      _listening = true;
      server.listen((request) async {
        if (request.method != 'GET' || request.uri.path != '/$_token') {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response.headers.contentType = ContentType.json;
          request.response.headers.set(
            HttpHeaders.cacheControlHeader,
            'no-store',
          );
          request.response.write(jsonEncode(_frame?.toJson()));
        }
        await request.response.close();
      });
    }
    final endpoint = Uri.parse('http://127.0.0.1:${server.port}/$_token');
    if (launcher != null) {
      await launcher!(endpoint);
    } else {
      await Process.start(
        Platform.resolvedExecutable,
        ['--expression-screen', endpoint.toString()],
        workingDirectory: File(Platform.resolvedExecutable).parent.path,
        mode: ProcessStartMode.detached,
      );
    }
    return true;
  }

  bool _listening = false;
  Future<void> dispose() async {
    _disposed = true;
    await _server?.close(force: true);
  }
}

class ScreenFeed {
  final Uri _endpoint;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  ScreenFeed(String source) : _endpoint = Uri.parse(source) {
    if (_endpoint.scheme != 'http' ||
        _endpoint.host != '127.0.0.1' ||
        !_endpoint.hasPort ||
        _endpoint.userInfo.isNotEmpty) {
      throw const FormatException('Only a local display endpoint is supported');
    }
  }
  Future<ExpressionFrame?> read() async {
    final request = await _client
        .getUrl(_endpoint)
        .timeout(const Duration(seconds: 2));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 2));
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    final raw = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 2));
    final value = jsonDecode(raw);
    return value == null
        ? null
        : ExpressionFrame.fromJson(Map<String, dynamic>.from(value as Map));
  }

  void close() {
    _client.close(force: true);
  }
}
