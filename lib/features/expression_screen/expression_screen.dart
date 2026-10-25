import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/plant_controller.dart';
import '../../app/pixel_display_controller.dart';
import '../../models/expression_frame.dart';
import '../../services/display/display_link.dart';
import '../../widgets/design.dart';
import '../../widgets/pixel_face.dart';

class ExpressionScreenPage extends StatefulWidget {
  final PlantController controller;
  const ExpressionScreenPage({super.key, required this.controller});
  @override
  State<ExpressionScreenPage> createState() => _ExpressionScreenPageState();
}

class _ExpressionScreenPageState extends State<ExpressionScreenPage> {
  PixelDisplayController get _display => widget.controller.pixelDisplay;
  bool _opening = false;
  String? _windowMessage;
  ExpressionFrame get _frame => _display.frame;
  @override
  void initState() {
    super.initState();
    _display.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ExpressionScreenPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.pixelDisplay.removeListener(_changed);
      _display.addListener(_changed);
    }
  }

  Future<void> _openWindow() async {
    setState(() {
      _opening = true;
      _windowMessage = null;
    });
    try {
      final opened = await _display.open();
      if (!mounted) return;
      setState(
        () => _windowMessage = opened
            ? 'Window launch requested. You can now return to Lab; Follow plant keeps the screen in sync.'
            : 'The browser blocked the window. Allow pop-ups for this app and try again.',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _windowMessage =
              'Could not open a display window. The embedded preview is still available.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  void dispose() {
    _display.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    return PageBody(
      title: 'A face for\nevery little feeling.',
      subtitle: 'Preview the pixel expressions for a future pot display.',
      eyebrow: 'PIXEL DISPLAY STUDIO',
      children: [
        const Tag('Software preview · no hardware connected', color: sky),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16221D),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF8BCB74), size: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${frame.name} · ${frame.expression.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Text(
                    '32 × 32',
                    style: TextStyle(color: Color(0xFFB7C8BC), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PixelFace(frame: frame),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                frame.source,
                style: const TextStyle(color: Color(0xFFB7C8BC), fontSize: 12),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _opening ? null : _openWindow,
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(_opening ? 'Opening…' : 'Open display window'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ExpressionSheet(name: frame.name),
            ),
          ),
          icon: const Icon(Icons.apps_rounded),
          label: const Text('Compare all expressions'),
        ),
        if (_windowMessage != null) Text(_windowMessage!),
        if (_display.syncError != null) Text(_display.syncError!),
        const SectionTitle('Choose how it feels'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in PreviewMode.values)
              ChoiceChip(
                label: Text(switch (mode) {
                  PreviewMode.follow => 'Follow plant',
                  PreviewMode.manual => 'Pick a scenario',
                  PreviewMode.tour => 'Auto preview',
                }),
                selected: _display.mode == mode,
                onSelected: (_) => _display.setMode(mode),
              ),
          ],
        ),
        if (_display.mode == PreviewMode.follow)
          SoftCard(
            color: mint,
            child: Text(
              'Uses the same simulated sensors and interaction state as Home. Priority: too warm, dry soil, low light, missing you, then happy/calm. '
              'Keep the display window open, then return to Lab or Weather to watch it react. Manual previews do not change plant data.',
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final expression in PixelExpression.values)
              ChoiceChip(
                label: Text(expression.title),
                selected: frame.expression == expression,
                onSelected: (_) => _display.select(expression),
              ),
          ],
        ),
        SoftCard(
          color: sun,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                frame.expression.scenario,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(frame.expression.description),
            ],
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Monochrome display'),
          subtitle: const Text(
            'White pixels for a single-color screen preview.',
          ),
          value: _display.monochrome,
          onChanged: _display.setMonochrome,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pause face animation'),
          subtitle: const Text(
            'Stop blinking and small expression accents. Auto preview is a separate mode.',
          ),
          value: _display.pauseMotion,
          onChanged: _display.setPauseMotion,
        ),
        const Text(
          'This is an expression preview, not real plant emotion detection. The future screen resolution, colors, refresh rate and communication protocol still need hardware confirmation. The display keeps running while you navigate. Closing the main app disconnects it.',
        ),
      ],
    );
  }
}

/// Runs without opening plant storage: a second process/tab only receives a
/// small display payload and cannot modify the profile, memories or rewards.
class ExpressionDisplayApp extends StatelessWidget {
  final String source;
  const ExpressionDisplayApp({super.key, required this.source});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Plant Heart - Pixel display',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: _DisplayViewer(source: source),
  );
}

class _DisplayViewer extends StatefulWidget {
  final String source;
  const _DisplayViewer({required this.source});
  @override
  State<_DisplayViewer> createState() => _DisplayViewerState();
}

class _DisplayViewerState extends State<_DisplayViewer> {
  ScreenFeed? _feed;
  Timer? _poll;
  ExpressionFrame? _frame;
  bool _busy = false, _connected = false;
  @override
  void initState() {
    super.initState();
    try {
      _feed = ScreenFeed(widget.source);
    } catch (_) {
      return;
    }
    _read();
    _poll = Timer.periodic(const Duration(milliseconds: 400), (_) => _read());
  }

  Future<void> _read() async {
    if (_busy || _feed == null) return;
    _busy = true;
    try {
      final next = await _feed!.read();
      if (!mounted) return;
      setState(() {
        _connected = next != null;
        if (next != null) _frame = next;
      });
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _feed?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _frame == null
                ? const Center(
                    child: Text('Waiting for the display controller…'),
                  )
                : PixelFace(frame: _frame!),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _connected
                  ? '${_frame!.name} · ${_frame!.expression.title}\n${_frame!.source} · software display'
                  : 'Controller disconnected · ${_frame == null ? 'no frame received' : 'showing last frame'}\nReopen the display from Pixel Display Studio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _connected
                    ? const Color(0xFFA8C8AB)
                    : const Color(0xFFFFD483),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ExpressionSheet extends StatelessWidget {
  final String name;
  const ExpressionSheet({super.key, required this.name});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Expression sheet'),
      backgroundColor: cream,
    ),
    body: SafeArea(
      child: PageBody(
        title: 'Small pixels.\nLots of personality.',
        subtitle: 'Eight preview scenarios for a future plant-pot display.',
        eyebrow: '32 × 32 · PIXEL EXPRESSION STUDY',
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 20,
              children: [
                for (final expression in PixelExpression.values)
                  SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: PixelFace(
                              frame: ExpressionFrame(
                                expression: expression,
                                name: name,
                                reducedMotion: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expression.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          expression.scenario,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Text(
            'Software preview only. These expressions represent fictional companion states.',
          ),
        ],
      ),
    ),
  );
}
