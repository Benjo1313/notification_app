import '../utils/Recurrence.dart';

/// Simple model to represent a timer entry
class TimerEntry {
  final String title;
  final int hours;
  final int minutes;
  final int seconds;
  final Recurrence recurrence; // structured recurrence model
  final DateTime start; // when the timer was created / started

  TimerEntry({required this.title, required this.hours, required this.minutes, required this.seconds, required this.recurrence, DateTime? start}) : start = start ?? DateTime.now();
}
