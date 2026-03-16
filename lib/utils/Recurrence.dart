enum RecurrenceType {
  once,
  daily,
  weekly,
  monthly,
  custom
}

class Recurrence {
  final RecurrenceType type;
  // only used for custom: every N units
  final int? every; // e.g., 3
  final String? unit; // 'days'|'weeks'|'months' (alternatively use enum)
  Recurrence({required this.type, this.every, this.unit});

  // convenience constructors
  factory Recurrence.once() => Recurrence(type: RecurrenceType.once);
  factory Recurrence.daily() => Recurrence(type: RecurrenceType.daily);
  factory Recurrence.weekly() => Recurrence(type: RecurrenceType.weekly);
  factory Recurrence.monthly() => Recurrence(type: RecurrenceType.monthly);
  factory Recurrence.custom(int every, String unit) => Recurrence(type: RecurrenceType.custom, every: every, unit: unit);

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'every': every,
    'unit': unit,
  };
  String getReadableString() {
    switch (type) {
      case RecurrenceType.once:
        return 'Once';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.custom:
        return 'Every ${every ?? '?'} ${unit ?? 'units'}';
    }
  }

  /// Returns the expiration DateTime for this recurrence given a start DateTime.
  ///
  /// - For `once` it returns the start (no recurrence) (or could be immediate expiration).
  /// - For `daily` it returns the end of the day (23:59:59.999) of [start].
  /// - For `weekly` it returns the end of the week (Sunday 23:59:59.999) containing [start].
  /// - For `monthly` it returns the end of the month containing [start].
  /// - For `custom` it uses the `every` and `unit` fields. Supported units: 'days','weeks','months'.
  DateTime expirationFrom(DateTime start) {
    final local = start.toLocal();
    switch (type) {
      case RecurrenceType.once:
        return local;
      case RecurrenceType.daily:
        return DateTime(local.year, local.month, local.day, 23, 59, 59, 999);
      case RecurrenceType.weekly:
        // Dart: DateTime.weekday: Monday=1 ... Sunday=7
        final daysUntilSunday = DateTime.sunday - local.weekday;
        final endOfWeek = local.add(Duration(days: daysUntilSunday));
        return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999);
      case RecurrenceType.monthly:
        final nextMonth = (local.month == 12) ? DateTime(local.year + 1, 1, 1) : DateTime(local.year, local.month + 1, 1);
        final lastDay = nextMonth.subtract(Duration(days: 1));
        return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59, 999);
      case RecurrenceType.custom:
        final n = every ?? 0;
        final u = (unit ?? 'days').toLowerCase();
        if (n <= 0) return local;
        if (u.startsWith('day')) {
          return DateTime(local.year, local.month, local.day).add(Duration(days: n)).add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        } else if (u.startsWith('week')) {
          return DateTime(local.year, local.month, local.day).add(Duration(days: n * 7)).add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
        } else if (u.startsWith('month')) {
          // add n months conservatively
          int targetMonth = local.month + n;
          int yearOffset = (targetMonth - 1) ~/ 12;
          targetMonth = ((targetMonth - 1) % 12) + 1;
          final targetYear = local.year + yearOffset;
          // take last day of target month
          final firstOfNext = (targetMonth == 12) ? DateTime(targetYear + 1, 1, 1) : DateTime(targetYear, targetMonth + 1, 1);
          final lastDay = firstOfNext.subtract(Duration(days: 1));
          return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59, 999);
        }
        // fallback to days
        return DateTime(local.year, local.month, local.day).add(Duration(days: n)).add(Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
    }
  }

  /// Returns a formatted remaining time string between [now] and the expiration derived from [start].
  ///
  /// Formatting rules:
  /// - If remaining <= 0 => 'Expired'
  /// - If remaining >= 24 hours => show days (e.g. '3 days')
  /// - If remaining < 24 hours and >= 1 hour => show 'Hh Mm' (e.g. '5h 30m')
  /// - If remaining < 1 hour => show 'Mm Ss' (e.g. '12m 05s')
  String formattedRemaining(DateTime now, DateTime start) {
    final exp = expirationFrom(start);
    final diff = exp.difference(now.toLocal());
    if (!diff.isNegative && diff.inMilliseconds == 0) return 'Expired';
    if (diff.isNegative) return 'Expired';

    final totalSeconds = diff.inSeconds;
    final days = totalSeconds ~/ (24 * 3600);
    final hours = (totalSeconds % (24 * 3600)) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (days >= 1) {
      return days == 1 ? '1 day' : '$days days';
    }

    if (hours >= 1) {
      final hStr = '${hours}h';
      final mStr = minutes > 0 ? ' ${minutes}m' : '';
      return '$hStr$mStr';
    }

    // less than 1 hour
    final mStr = '${minutes}m';
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr ${sStr}s';
  }


  static Recurrence fromJson(Map<String, dynamic> m) {
    final typeStr = (m['type'] as String?) ?? 'RecurrenceType.none';
    final type = RecurrenceType.values.firstWhere((e) => e.toString() == typeStr, orElse: () => RecurrenceType.once);
    return Recurrence(type: type, every: m['every'] as int?, unit: m['unit'] as String?);
  }
}
