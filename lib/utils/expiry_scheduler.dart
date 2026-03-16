import 'dart:async';
import 'package:flutter/foundation.dart';

import 'Recurrence.dart';

/// Schedules adaptive updates for a remaining/expiry display.
///
/// Usage:
/// final notifier = ValueNotifier<String>('');
/// final s = ExpiryScheduler(recurrence, start, notifier);
/// s.start();
/// // when recurrence/start change: s.update(newRecurrence, newStart);
/// // when done: s.dispose();
class ExpiryScheduler {
  Recurrence _recurrence;
  DateTime _start;
  final ValueNotifier<String> notifier;

  Timer? _timer;

  ExpiryScheduler(this._recurrence, this._start, this.notifier);

  void start() {
    _schedule();
  }

  void update(Recurrence recurrence, DateTime start) {
    _recurrence = recurrence;
    _start = start;
    notifier.value = _recurrence.formattedRemaining(DateTime.now(), _start);
    _schedule();
  }

  void dispose() {
    _timer?.cancel();
  }

  void _schedule() {
    _timer?.cancel();

    final now = DateTime.now().toLocal();
    final exp = _recurrence.expirationFrom(_start);
    final remaining = exp.difference(now);

    // update immediately
    notifier.value = _recurrence.formattedRemaining(now, _start);

    if (remaining.isNegative || remaining == Duration.zero) {
      return;
    }

    Duration nextTick;

    if (remaining > const Duration(hours: 24)) {
      final until24h = remaining - const Duration(hours: 24);
      final candidate = until24h > const Duration(hours: 1) ? const Duration(hours: 1) : until24h;
      // align to next hour boundary using DateTime difference so we handle rollovers correctly
      final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
      final timeToNextHour = nextHour.difference(now);
      nextTick = candidate < timeToNextHour ? candidate : timeToNextHour;
    } else if (remaining > const Duration(hours: 1)) {
      final until1h = remaining - const Duration(hours: 1);
      final candidate = until1h > const Duration(minutes: 1) ? const Duration(minutes: 1) : until1h;
      // align to next minute boundary
      final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
      final timeToNextMinute = nextMinute.difference(now);
      nextTick = candidate < timeToNextMinute ? candidate : timeToNextMinute;
    } else {
      // align to next second
      final nextSecond = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second + 1);
      final timeToNextSecond = nextSecond.difference(now);
      nextTick = timeToNextSecond <= Duration.zero ? const Duration(seconds: 1) : timeToNextSecond;
    }

    if (nextTick <= Duration.zero) nextTick = const Duration(seconds: 1);

    _timer = Timer(nextTick, () {
      // update notifier and reschedule
      notifier.value = _recurrence.formattedRemaining(DateTime.now(), _start);
      _schedule();
    });
  }
}
