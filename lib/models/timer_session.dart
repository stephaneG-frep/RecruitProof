import 'activity.dart';

class TimerSession {
  const TimerSession({
    required this.type,
    required this.startedAt,
    required this.elapsed,
    required this.isRunning,
  });

  final ActionType type;
  final DateTime startedAt;
  final Duration elapsed;
  final bool isRunning;
}
