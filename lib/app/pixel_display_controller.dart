import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expression_frame.dart';
import '../services/display/display_link.dart';

enum PreviewMode { follow, manual, tour }

/// App-lifetime display session: the separate screen keeps following Lab/Weather
/// after the user leaves the studio. This controller never edits plant data.
class PixelDisplayController extends ChangeNotifier {
  final Listenable plant;
  final ExpressionFrame Function() followFrame;
  final _host = DisplayHost();
  PreviewMode mode = PreviewMode.follow;
  PixelExpression selected = PixelExpression.happy;
  bool monochrome = false, pauseMotion = false;
  String? syncError;
  Timer? _tour;
  PixelDisplayController(this.plant, this.followFrame) {
    plant.addListener(_changed);
  }
  ExpressionFrame get frame {
    final live = followFrame();
    return ExpressionFrame(
      expression: mode == PreviewMode.follow ? live.expression : selected,
      name: live.name,
      monochrome: monochrome,
      reducedMotion: pauseMotion || live.reducedMotion,
      source: switch (mode) {
        PreviewMode.follow => 'Following simulated plant',
        PreviewMode.manual => 'Scenario preview',
        PreviewMode.tour => 'Auto preview · every 3 seconds',
      },
    );
  }

  void _publish() {
    try {
      _host.publish(frame);
      syncError = null;
    } catch (_) {
      syncError = 'Window sync unavailable. The embedded preview still works.';
    }
  }

  void _changed() {
    _publish();
    notifyListeners();
  }

  void setMode(PreviewMode next) {
    _tour?.cancel();
    mode = next;
    if (next == PreviewMode.tour) {
      selected = PixelExpression.happy;
      _tour = Timer.periodic(const Duration(seconds: 3), (_) {
        selected = PixelExpression
            .values[(selected.index + 1) % PixelExpression.values.length];
        _changed();
      });
    }
    _changed();
  }

  void select(PixelExpression next) {
    _tour?.cancel();
    mode = PreviewMode.manual;
    selected = next;
    _changed();
  }

  void setMonochrome(bool next) {
    monochrome = next;
    _changed();
  }

  void setPauseMotion(bool next) {
    pauseMotion = next;
    _changed();
  }

  Future<bool> open() {
    _publish();
    return _host.open();
  }

  @override
  void dispose() {
    plant.removeListener(_changed);
    _tour?.cancel();
    unawaited(_host.dispose());
    super.dispose();
  }
}
