import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/demo_growth.dart';
import '../../widgets/design.dart';

class GrowthMoviePage extends StatefulWidget {
  const GrowthMoviePage({super.key});
  @override
  State<GrowthMoviePage> createState() => _GrowthMoviePageState();
}

class _GrowthMoviePageState extends State<GrowthMoviePage>
    with WidgetsBindingObserver {
  VideoPlayerController? player;
  String? error;
  bool ready = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && ready) unawaited(player!.pause());
  }

  Future<void> load() async {
    final token = ++generation;
    final old = player;
    final next = VideoPlayerController.asset(growthMovieAsset);
    setState(() {
      player = next;
      ready = false;
      error = null;
    });
    if (old != null) {
      old.removeListener(playbackChanged);
      unawaited(old.dispose());
    }
    next.addListener(playbackChanged);
    try {
      await next.initialize().timeout(const Duration(seconds: 15));
      await next.setVolume(0);
      if (mounted && token == generation) setState(() => ready = true);
    } catch (_) {
      if (mounted && token == generation) {
        setState(
          () => error =
              'The video could not be opened on this device. Retry, or explore the six illustrated checkpoints below.',
        );
      }
    }
  }

  void playbackChanged() {
    if (mounted && player!.value.hasError && error == null) {
      setState(
        () => error = 'Playback is unavailable. Please retry opening the film.',
      );
    }
  }

  Future<void> control(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Playback is unavailable. Please retry opening the film.',
        );
      }
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    final p = player;
    if (p != null) {
      p.removeListener(playbackChanged);
      unawaited(p.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('From seed to bloom'),
      backgroundColor: cream,
    ),
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Tag('Illustrated demo · 18 seconds · silent', color: sky),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: Colors.black,
                  child: ready && error == null
                      ? Semantics(
                          label: 'Illustrated seed-to-bloom video',
                          child: VideoPlayer(player!),
                        )
                      : Image.asset(
                          growthCheckpoints.last.image,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
          ),
          if (ready && error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: player!,
                builder: (context, value, _) => Column(
                  children: [
                    Row(
                      children: [
                        IconButton.filled(
                          tooltip: value.isPlaying
                              ? 'Pause bloom film'
                              : 'Play bloom film',
                          onPressed: () => control(() async {
                            if (value.isPlaying) {
                              await player!.pause();
                            } else {
                              if (value.position >= value.duration) {
                                await player!.seekTo(Duration.zero);
                              }
                              await player!.play();
                            }
                          }),
                          icon: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${movieTime(value.position)} / ${movieTime(value.duration)}',
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Replay bloom film',
                          onPressed: () => control(() async {
                            await player!.seekTo(Duration.zero);
                            await player!.play();
                          }),
                          icon: const Icon(Icons.replay),
                        ),
                      ],
                    ),
                    Slider(
                      label: movieTime(value.position),
                      semanticFormatterCallback: (v) =>
                          'Bloom film ${movieTime(Duration(milliseconds: v.round()))}',
                      value: value.position.inMilliseconds.toDouble().clamp(
                        0,
                        value.duration.inMilliseconds.toDouble(),
                      ),
                      max: value.duration.inMilliseconds.toDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      onChanged: (v) => control(
                        () => player!.seekTo(Duration(milliseconds: v.round())),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              children: [
                if (error != null) ...[
                  Text(error!),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry video'),
                  ),
                  const SizedBox(height: 12),
                ] else if (!ready)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Opening your demo film…'),
                      ],
                    ),
                  ),
                const Text(
                  'Sunny’s first season',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Six illustrated demo checkpoints make up this sample film. It uses bundled footage, not photos of your selected plant. Real photo-based movie generation is a future step.',
                ),
                const SizedBox(height: 20),
                const SectionTitle('Jump to a moment'),
                const SizedBox(height: 12),
                for (final stage in growthCheckpoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      padding: const EdgeInsets.all(10),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            stage.image,
                            width: 72,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(stage.title),
                        subtitle: Text(
                          'Day ${stage.day} · ${movieTime(stage.position)}',
                        ),
                        trailing: const Icon(Icons.play_circle_outline),
                        onTap: !ready || error != null
                            ? null
                            : () =>
                                  control(() => player!.seekTo(stage.position)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String movieTime(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
