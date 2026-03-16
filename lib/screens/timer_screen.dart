import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

import '../models/timer_entry.dart';
import '../widgets/timer_card.dart';
import '../utils/Recurrence.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<TimerEntry> _timers = [];

  Future<void> _showAddTimerDialog() async {
  final TextEditingController nameCtrl = TextEditingController();
  Duration selectedDuration = const Duration(minutes: 1);
  // controllers for custom recurrence inputs
  final TextEditingController recurrenceDaysCtrl = TextEditingController();
  final TextEditingController recurrenceWeeksCtrl = TextEditingController();
  final TextEditingController recurrenceMonthsCtrl = TextEditingController();
    final List<String> recurrenceOptions = ['once', 'daily', 'weekly', 'monthly', 'Custom'];
    String selectedRecurrence = recurrenceOptions[0];
    bool isCustomRecurrence = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Timer'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  // Duration picker trigger — shows a Cupertino wheel picker in a bottom sheet
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      // show CupertinoTimerPicker in a bottom sheet and await the picked duration
                      final Duration? picked = await showModalBottomSheet<Duration>(
                        context: context,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        builder: (ctx) {
                          Duration temp = selectedDuration;
                          return SizedBox(
                            height: 300,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 216,
                                  child: StatefulBuilder(
                                    builder: (context, setModalState) {
                                      // Custom 3-column picker to support hours > 23
                                      const int maxHours = 999; // change as needed
                                      int tempHours = temp.inHours;
                                      int tempMinutes = (temp.inMinutes % 60);
                                      int tempSeconds = (temp.inSeconds % 60);

                                      return Row(
                                        children: [
                                          // Hours picker
                                          Expanded(
                                            child: CupertinoPicker(
                                              backgroundColor: Theme.of(ctx).colorScheme.surface,
                                              itemExtent: 32,
                                              scrollController: FixedExtentScrollController(initialItem: tempHours.clamp(0, maxHours)),
                                              onSelectedItemChanged: (i) {
                                                setModalState(() {
                                                  tempHours = i;
                                                  temp = Duration(hours: tempHours, minutes: tempMinutes, seconds: tempSeconds);
                                                });
                                              },
                                              children: List<Widget>.generate(
                                                maxHours + 1,
                                                (i) => Center(
                                                  child: Text(
                                                    '$i h',
                                                    style: TextStyle(
                                                      color: Theme.of(ctx).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Minutes picker
                                          Expanded(
                                            child: CupertinoPicker(
                                              backgroundColor: Theme.of(ctx).colorScheme.surface,
                                              itemExtent: 32,
                                              scrollController: FixedExtentScrollController(initialItem: tempMinutes),
                                              onSelectedItemChanged: (i) {
                                                setModalState(() {
                                                  tempMinutes = i;
                                                  temp = Duration(hours: tempHours, minutes: tempMinutes, seconds: tempSeconds);
                                                });
                                              },
                                              children: List<Widget>.generate(
                                                60,
                                                (i) => Center(
                                                  child: Text(
                                                    '${i.toString().padLeft(2, '0')} m',
                                                    style: TextStyle(
                                                      color: Theme.of(ctx).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Seconds picker
                                          Expanded(
                                            child: CupertinoPicker(
                                              backgroundColor: Theme.of(ctx).colorScheme.surface,
                                              itemExtent: 32,
                                              scrollController: FixedExtentScrollController(initialItem: tempSeconds),
                                              onSelectedItemChanged: (i) {
                                                setModalState(() {
                                                  tempSeconds = i;
                                                  temp = Duration(hours: tempHours, minutes: tempMinutes, seconds: tempSeconds);
                                                });
                                              },
                                              children: List<Widget>.generate(
                                                60,
                                                (i) => Center(
                                                  child: Text(
                                                    '${i.toString().padLeft(2, '0')} s',
                                                    style: TextStyle(
                                                      color: Theme.of(ctx).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(temp),
                                      child: const Text('Done'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      if (picked != null) {
                        // Update the dialog UI via the StatefulBuilder's setState
                        setState(() {
                          selectedDuration = picked;
                        });
                      }
                    },
                    child: Builder(builder: (context) {
                      // show the currently selected duration
                      String durLabel() {
                        final h = selectedDuration.inHours;
                        final m = (selectedDuration.inMinutes % 60);
                        final s = (selectedDuration.inSeconds % 60);
                        if (h > 0) return '${h}h ${m}m ${s}s';
                        if (m > 0) return '${m}m ${s}s';
                        return '${s}s';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('Duration: ${durLabel()}')),
                            const Icon(Icons.expand_less),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRecurrence,
                    decoration: const InputDecoration(labelText: 'Recurrence'),
                    items: recurrenceOptions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedRecurrence = v ?? recurrenceOptions[0];
                        isCustomRecurrence = selectedRecurrence == 'Custom';
                      });
                    },
                  ),
                  if (isCustomRecurrence) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: recurrenceDaysCtrl,
                            decoration: const InputDecoration(labelText: 'Days'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: recurrenceWeeksCtrl,
                            decoration: const InputDecoration(labelText: 'Weeks'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: recurrenceMonthsCtrl,
                            decoration: const InputDecoration(labelText: 'Months'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
              ElevatedButton(
                onPressed: () {
                  final String name = nameCtrl.text.trim().isEmpty ? 'Timer' : nameCtrl.text.trim();

                  // Use the duration selected by the Cupertino wheels (selectedDuration).
                  // This allows the hour picker to exceed 23 hours as requested.
                  final int hours = selectedDuration.inHours;
                  final int minutes = selectedDuration.inMinutes % 60;
                  final int seconds = selectedDuration.inSeconds % 60;

                  // Build a Recurrence object based on selection or custom input
                  Recurrence recurrenceObj;
                  if (isCustomRecurrence) {
                    final int days = int.tryParse(recurrenceDaysCtrl.text.trim()) ?? 0;
                    final int weeks = int.tryParse(recurrenceWeeksCtrl.text.trim()) ?? 0;
                    final int months = int.tryParse(recurrenceMonthsCtrl.text.trim()) ?? 0;

                    if (days > 0) {
                      recurrenceObj = Recurrence.custom(days, 'days');
                    } else if (weeks > 0) {
                      recurrenceObj = Recurrence.custom(weeks, 'weeks');
                    } else if (months > 0) {
                      recurrenceObj = Recurrence.custom(months, 'months');
                    } else {
                      // No value entered: fallback to once
                      recurrenceObj = Recurrence.once();
                    }
                  } else {
                    switch (selectedRecurrence) {
                      case 'daily':
                        recurrenceObj = Recurrence.daily();
                        break;
                      case 'weekly':
                        recurrenceObj = Recurrence.weekly();
                        break;
                      case 'monthly':
                        recurrenceObj = Recurrence.monthly();
                        break;
                      case 'once':
                      default:
                        recurrenceObj = Recurrence.once();
                        break;
                    }
                  }

                  // Ensure at least 1 second total duration
                  final totalSeconds = hours * 3600 + minutes * 60 + seconds;

                  setState(() {
                    if (totalSeconds <= 0) {
                      // fallback to 1 minute if user left everything empty
                      _timers.add(TimerEntry(title: name, hours: 0, minutes: 1, seconds: 0, recurrence: recurrenceObj, start: DateTime.now()));
                    } else {
                      _timers.add(TimerEntry(title: name, hours: hours, minutes: minutes, seconds: seconds, recurrence: recurrenceObj, start: DateTime.now()));
                    }
                  });

                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // The app bar at the top
      appBar: AppBar(
        title: const Text('My Goals'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.background,
      // Body contains our timer cards in a scrollable list or an empty state
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _timers.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_off,
                      size: 72,
                      color: theme.iconTheme.color != null
                          ? Color.fromRGBO(theme.iconTheme.color!.red, theme.iconTheme.color!.green, theme.iconTheme.color!.blue, 0.6)
                          : Color.fromRGBO(colorScheme.onBackground.red, colorScheme.onBackground.green, colorScheme.onBackground.blue, 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No timers yet',
                      style: TextStyle(fontSize: 18, color: theme.textTheme.titleMedium?.color ?? colorScheme.onBackground),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first timer',
                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color ?? Color.fromRGBO(colorScheme.onBackground.red, colorScheme.onBackground.green, colorScheme.onBackground.blue, 0.8)),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _timers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  try {
                    final t = _timers[index];
                    // Defensive: log the values so we can catch unexpected nulls at runtime
                    debugPrint('Building TimerCard index=$index title=${t.title} minutes=${t.minutes} recurrence=${t.recurrence.type.toString().split('.').last}');
                    return TimerCard(
                      key: ValueKey('${t.title}_$index'),
                      title: t.title,
                      goalHours: t.hours,
                      goalMinutes: t.minutes,
                      goalSeconds: t.seconds,
                      onDelete: () {
                        setState(() {
                          _timers.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted "${t.title}"')),
                        );
                      },
                      recurrence: t.recurrence, // Placeholder recurrence value
                      start: t.start,
                    );
                  } catch (e, st) {
                    // Catch build-time errors for a single item to avoid crashing the whole list.
                    debugPrint('Error building TimerCard at index=$index: $e\n$st');
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(244, 67, 54, 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color.fromRGBO(244, 67, 54, 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invalid timer', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('An error occurred while building this timer. Check logs.', style: TextStyle(color: Colors.red[400])),
                        ],
                      ),
                    );
                  }
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
