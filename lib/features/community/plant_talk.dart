import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/plant_controller.dart';
import '../../models/expression_frame.dart';
import '../../models/plant_exchange.dart';
import '../../services/neighbourhood.dart';
import '../../widgets/design.dart';
import '../../widgets/pixel_face.dart';

class PlantTalkPage extends StatefulWidget {
  final PlantController controller;
  const PlantTalkPage({super.key, required this.controller});
  @override
  State<PlantTalkPage> createState() => _PlantTalkPageState();
}

class _PlantTalkPageState extends State<PlantTalkPage>
    with WidgetsBindingObserver {
  Timer? timer;
  bool running = false;
  int round = 0, visibleLines = 0, lineEndsAt = 0;
  String? liveId, plantId;
  PlantController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && running) pause();
  }

  void pause() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        running = false;
        liveId = null;
      });
    }
  }

  void newExchange() {
    final neighbour = demoNeighbours[round % 3];
    unawaited(c.exchangeWith(neighbour));
    liveId = c.data.plantExchanges.last.id;
    round++;
    visibleLines = 1;
    lineEndsAt = DateTime.now()
        .add(const Duration(milliseconds: 1300))
        .millisecondsSinceEpoch;
  }

  void start() {
    timer?.cancel();
    setState(() {
      running = true;
      round = 0;
      plantId = c.activePlantId;
      newExchange();
    });
    timer = Timer.periodic(const Duration(milliseconds: 1300), (_) {
      if (!mounted || c.activePlantId != plantId) {
        pause();
        return;
      }
      setState(() {
        if (visibleLines < 4) {
          visibleLines++;
          lineEndsAt = DateTime.now()
              .add(const Duration(milliseconds: 1300))
              .millisecondsSinceEpoch;
        } else if (round < 3) {
          newExchange();
        } else {
          timer?.cancel();
          running = false;
          liveId = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = c.data.plantExchanges.reversed.take(6).toList();
    final current = history.where((e) => e.id == liveId).firstOrNull;
    final speaking = current?.lines[(visibleLines - 1).clamp(0, 3)];
    return PageBody(
      title: 'A little leaf\nconversation.',
      subtitle: '${c.data.name} meets the neighbourhood, one hello at a time.',
      eyebrow: 'PLANTS TALK TO PLANTS',
      children: [
        const Tag(
          'Local role-play · simulated plant conversations',
          color: sky,
        ),
        SoftCard(
          color: mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                running
                    ? 'Plants are chatting · $round/3'
                    : round == 3
                    ? 'A lovely round of introductions.'
                    : 'Let the plants say hello.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'They take turns reading shared demo journals, comparing care conditions and offering a kind observation. No typing needed.',
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: running ? pause : start,
                icon: Icon(
                  running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  running ? 'Pause plant talk' : 'Start automatic plant talk',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'One round visits Fern, Pip and Luna. It stops after three introductions, when you leave this section or when the app goes into the background.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (speaking != null)
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 88,
                  height: 66,
                  child: PixelFace(
                    frame: ExpressionFrame(
                      expression: PixelExpression.curious,
                      name: speaking.speaker,
                      reducedMotion: c.data.reducedMotion,
                      interaction: InteractionPhase.replying,
                      replyId: visibleLines,
                      replyEndsAtMs: lineEndsAt,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${speaking.speaker} is speaking…',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        if (history.isEmpty)
          const SoftCard(
            child: Text(
              'Start a round and watch the plants introduce themselves. Their shared conversation will stay here on this device.',
            ),
          ),
        for (final exchange in history) _exchange(context, exchange),
        if (c.data.plantExchanges.length > 6)
          Text(
            'Showing the latest 6 of ${c.data.plantExchanges.length} saved conversations.',
          ),
        const Text(
          'Replies use local care rules, not an online AI. Observations are illustrative. Conversations never read your private chat or memories, change readings, or water a plant.',
        ),
      ],
    );
  }

  Widget _exchange(BuildContext context, PlantExchange exchange) {
    final count = exchange.id == liveId ? visibleLines : exchange.lines.length;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exchange.observation,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${dateLabelForTalk(exchange.at)} · demo exchange',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 14),
          for (final line in exchange.lines.take(count))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.speaker,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: leaf,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(line.text),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String dateLabelForTalk(DateTime at) =>
    '${at.toLocal().hour.toString().padLeft(2, '0')}:${at.toLocal().minute.toString().padLeft(2, '0')}';
