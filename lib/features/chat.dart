import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../widgets/design.dart';
import '../widgets/pixel_face.dart';
import '../models/expression_frame.dart';

class ChatPage extends StatefulWidget {
  final PlantController controller;
  const ChatPage({super.key, required this.controller});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool sending = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? prompt]) async {
    final text = (prompt ?? input.text).trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    input.clear();
    final saved = await widget.controller.send(text);
    if (!mounted) return;
    setState(() => sending = false);
    if (!saved) feedback(context, false, '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.controller.data;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 650;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk with ${d.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Typed input simulates future voice. Local rules only; no audio is recorded or generated.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: widget.controller.pixelDisplay,
              builder: (context, _) {
                final display = widget.controller.pixelDisplay;
                final frame = display.frame;
                final playing = frame.interaction == InteractionPhase.replying;
                final paused =
                    frame.reducedMotion ||
                    MediaQuery.disableAnimationsOf(context);
                final last = d.messages
                    .where((m) => m.kind == 'plant')
                    .lastOrNull;
                return Column(
                  children: [
                    SizedBox(
                      height: compact ? 88 : 128,
                      width: double.infinity,
                      child: PixelFace(frame: frame),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              playing
                                  ? paused
                                        ? 'Reply ready · motion paused'
                                        : 'Replying · visual animation only'
                                  : 'Ready for a simulated conversation',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Replay reply animation',
                            onPressed: last == null
                                ? null
                                : () => display.playReply(last.text),
                            icon: const Icon(Icons.replay_rounded, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Open response display',
                            onPressed: () async {
                              try {
                                final opened = await display.open();
                                if (context.mounted) {
                                  feedback(
                                    context,
                                    opened,
                                    'Display window launch requested.',
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  feedback(context, false, '');
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  if (d.messages.isEmpty)
                    SoftCard(
                      color: mint,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.waving_hand_outlined, color: leaf),
                          const SizedBox(height: 14),
                          Text(
                            'Hello, I’m ${d.name}.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tell me about your day, ask about my care, or plant a memory. A little company goes a long way.',
                          ),
                        ],
                      ),
                    ),
                  for (final message in d.messages)
                    Align(
                      alignment: message.kind == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(maxWidth: 330),
                        decoration: BoxDecoration(
                          color: message.kind == 'user' ? sky : mint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.kind == 'user' ? 'You' : d.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(message.text),
                            const SizedBox(height: 6),
                            Text(
                              dateLabel(message.at),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (sending)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Saving your conversation…'),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final prompt in [
                    'How are you feeling today?',
                    'How should I care for you?',
                    'What do you remember?',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(prompt),
                        onPressed: sending ? null : () => send(prompt),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Type simulated voice input…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: sending ? null : send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(50, 50),
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  'Try “Remember that I love rainy days.” This is a prototype, not professional support.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
          ],
        );
      },
    );
  }
}
