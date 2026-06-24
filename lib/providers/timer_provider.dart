import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _ticker;
  ActionType _type = ActionType.offerSearch;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  ActionType get type => _type;
  DateTime? get startedAt => _startedAt;
  Duration get elapsed => _elapsed;
  bool get isRunning => _running;
  bool get hasSession => _startedAt != null;

  void setType(ActionType value) {
    if (hasSession) return;
    _type = value;
    notifyListeners();
  }

  void start() {
    if (hasSession) return;
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _running = true;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    _running = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (!hasSession || _running) return;
    _running = true;
    _startTicker();
    notifyListeners();
  }

  ({DateTime start, DateTime end, Duration elapsed, ActionType type}) stop() {
    final result = (
      start: _startedAt!,
      end: _startedAt!.add(_elapsed),
      elapsed: _elapsed,
      type: _type,
    );
    _ticker?.cancel();
    _startedAt = null;
    _elapsed = Duration.zero;
    _running = false;
    notifyListeners();
    return result;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running) {
        _elapsed += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
