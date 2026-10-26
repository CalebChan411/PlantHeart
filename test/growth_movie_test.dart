import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:plant_heart/features/memoir/growth_movie.dart';
import 'package:plant_heart/models/demo_growth.dart';

class TestMoviePlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> streams = {};
  int serial = 0;
  Duration position = Duration.zero;
  bool playing = false, fail = false;
  final List<int> disposed = [];
  final disposedSignal = Completer<void>();
  DataSource? source;
  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource dataSource) async {
    source = dataSource;
    final id = ++serial;
    final stream = streams[id] = StreamController<VideoEvent>();
    if (fail) {
      stream.addError(
        PlatformException(
          code: 'decode-error',
          message: 'Demo codec unavailable',
        ),
      );
    } else {
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 18),
          size: const Size(960, 540),
        ),
      );
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    if (!disposedSignal.isCompleted) disposedSignal.complete();
    await streams[playerId]?.close();
  }

  @override
  Future<void> play(int playerId) async {
    playing = true;
  }

  @override
  Future<void> pause(int playerId) async {
    playing = false;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration value) async {
    position = value;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.black);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VideoPlayerPlatform original;
  late TestMoviePlatform video;
  setUp(() {
    original = VideoPlayerPlatform.instance;
    video = TestMoviePlatform();
    VideoPlayerPlatform.instance = video;
  });
  tearDown(() {
    VideoPlayerPlatform.instance = original;
  });
  Future<void> start(WidgetTester t) async {
    t.view.physicalSize = const Size(480, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(const MaterialApp(home: GrowthMoviePage()));
    await t.pumpAndSettle();
  }

  testWidgets(
    'movie uses a local asset, plays, pauses, seeks, replays and disposes',
    (t) async {
      await start(t);
      expect(video.source!.sourceType, DataSourceType.asset);
      expect(video.source!.asset, growthMovieAsset);
      expect(video.playing, isFalse);
      await t.tap(find.byTooltip('Play bloom film'));
      await t.pump();
      expect(video.playing, isTrue);
      await t.tap(find.byTooltip('Pause bloom film'));
      await t.pump();
      expect(video.playing, isFalse);
      await t.scrollUntilVisible(
        find.text('Our first bloom'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        t.element(find.text('Our first bloom')),
        alignment: .5,
      );
      await t.pumpAndSettle();
      for (
        var i = 0;
        i < 8 && find.text('Our first bloom').hitTestable().evaluate().isEmpty;
        i++
      ) {
        await t.drag(find.byType(ListView), const Offset(0, -180));
        await t.pumpAndSettle();
      }
      expect(find.text('Our first bloom').hitTestable(), findsOneWidget);
      await t.tap(find.text('Our first bloom'));
      await t.pump();
      expect(video.position, const Duration(seconds: 15));
      await t.drag(find.byType(ListView), const Offset(0, 1600));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Replay bloom film'));
      await t.pump();
      expect(video.position, Duration.zero);
      expect(video.playing, isTrue);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(video.playing, isFalse);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await t.runAsync(
        () => video.disposedSignal.future.timeout(const Duration(seconds: 3)),
      );
      expect(video.disposed, contains(1));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'decoder failure shows a real retry path and checkpoint fallback',
    (t) async {
      video.fail = true;
      await start(t);
      expect(find.textContaining('could not be opened'), findsOneWidget);
      expect(find.text('Retry video'), findsOneWidget);
      video.fail = false;
      await t.tap(find.text('Retry video'));
      await t.pumpAndSettle();
      expect(find.byTooltip('Play bloom film'), findsOneWidget);
      video.streams[2]!.addError(
        PlatformException(code: 'runtime-error', message: 'Decoder stopped'),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('Playback is unavailable'), findsOneWidget);
      expect(find.text('Retry video'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
}
