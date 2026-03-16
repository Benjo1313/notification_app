import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/Recurrence.dart';
import '../utils/expiry_scheduler.dart';
import '../services/notification_service.dart';

class TimerCard extends StatefulWidget {
  final String title;
  final int goalHours; 
  final int goalMinutes;
  final int goalSeconds;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; // future support for an edit callback function
  final Recurrence recurrence; 
  final DateTime start;

  // `start` is the DateTime the timer/recurrence was created or set.
  // If not provided the constructor will default it to `DateTime.now()`.
  TimerCard({
    super.key,
    required this.title,
    required this.goalHours,
    required this.goalMinutes,
    required this.goalSeconds,
    this.onDelete,
    this.onEdit,
    required this.recurrence,
    DateTime? start,
  }) : start = start ?? DateTime.now();

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  Timer? _timer;
  late final ExpiryScheduler _expiryScheduler;
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _isCompleted = false;
  late final ValueNotifier<String> _expiryText;
  late final int _notificationId; // unique per timer

  @override
  void initState() {
    super.initState();
    _notificationId = widget.start.millisecondsSinceEpoch.remainder(100000);
    // Initialize remaining seconds to the total goal when widget is created
    _remainingSeconds = widget.goalHours * 3600 + widget.goalMinutes * 60 + widget.goalSeconds;
    _expiryText = ValueNotifier(widget.recurrence.formattedRemaining(DateTime.now(), widget.start));
    _expiryScheduler = ExpiryScheduler(widget.recurrence, widget.start, _expiryText);
    _expiryScheduler.start();
  }

  @override
  void didUpdateWidget(covariant TimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if start or recurrence changed, reschedule
    if (oldWidget.start != widget.start || oldWidget.recurrence != widget.recurrence) {
      _expiryScheduler.update(widget.recurrence, widget.start);
    }
  }

  // Convert seconds to a nice H:MM:SS or MM:SS format
  String _formatTime(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    if (h > 0) {
      return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  // Calculate progress as a percentage (0.0 to 1.0)
  double _getProgress() {
    int goalSeconds = widget.goalHours * 3600 + widget.goalMinutes * 60 + widget.goalSeconds;
    if (goalSeconds == 0) return 0;
    int elapsedSeconds = goalSeconds - _remainingSeconds;
    double progress = elapsedSeconds / goalSeconds;
    return progress > 1.0 ? 1.0 : progress;
  }

  // Start or resume the timer
  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _scheduleOneHourWarning();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // If widget was removed from the tree, stop the timer to avoid
      // calling setState / using context on a disposed State.
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // stop periodic timer and handle completion
        timer.cancel();
        _completeTimer();
      }
    });
  }

  // Pause the timer
  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });

    _timer?.cancel();
    _cancelOneHourWarning();
  }

  // Complete/Reset the timer
  void _completeTimer() {
    _timer?.cancel();
    _cancelOneHourWarning();

    setState(() {
      _isCompleted = true;
      _isRunning = false;
      _remainingSeconds = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title}: You took the easy way out, timer completed.')),
      );
      _showCompletionDialog();
    }
  }

  void _undoCompleteTimer() {
    setState(() {
      _isCompleted = false;
      _remainingSeconds = widget.goalHours * 3600 + widget.goalMinutes * 60 + widget.goalSeconds;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.title}: Timer completion undone. Back to work!')),
      );
    }
  }

  void _scheduleOneHourWarning() {
    // cancel any existing scheduled warning for this timer
    _cancelOneHourWarning();

    if (_remainingSeconds <= 0) return;

    // If less than or equal to 1 hour remains, show notification now
    if (_remainingSeconds <= 3600) {
      NotificationService.instance.showNow(
        id: _notificationId,
        title: 'Timer nearly expired',
        body: '${widget.title} is less than 1 hour from expiring.',
      );
      return;
    }

    final scheduled = DateTime.now().add(Duration(seconds: _remainingSeconds - 3600));
    NotificationService.instance.scheduleNotification(
      id: _notificationId,
      title: '1 hour left',
      body: '${widget.title} will expire in 1 hour.',
      scheduledDate: scheduled,
    );
  }

  void _cancelOneHourWarning() {
    NotificationService.instance.cancel(_notificationId);
  }

  Future<void> _showCompletionDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Timer Completed'),
          content: Text('${widget.title} has completed.'),
          actions: [
            TextButton(
              onPressed: () {
                // Delete / close the timer
                widget.onDelete?.call();
                Navigator.of(ctx).pop();
              },
              child: const Text('Close Timer'),
            ),
            TextButton(
              onPressed: () {
                // Restart the timer: reset and start
                Navigator.of(ctx).pop();
                _undoCompleteTimer();
                // start immediately after restart
                _startTimer();
              },
              child: const Text('Restart Timer'),
            ),
          ],
        );
      },
    );
  }

  // Clean up when widget is removed
  @override
  void dispose() {
    _timer?.cancel();
    _expiryScheduler.dispose();
    _expiryText.dispose();
    _cancelOneHourWarning();
    super.dispose();
  }

  String _buildGoalLabel() {
    final parts = <String>[];
    if (widget.goalHours > 0) parts.add('${widget.goalHours}h');
    if (widget.goalMinutes > 0) parts.add('${widget.goalMinutes}m');
    if (widget.goalSeconds > 0) parts.add('${widget.goalSeconds}s');
    if (parts.isEmpty) return '0s goal';
    return parts.join(' ')+ ' goal';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildGoalLabel(),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color ?? colorScheme.onSurfaceVariant,
                      ),
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: _expiryText,
                      builder: (context, value, _) {
                        return Text(_isCompleted ? 'Restarts: $value' : 'Expires: $value',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall?.color ?? colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isCompleted ? Colors.blue.withValues(alpha: 0.12) : _isRunning ? Colors.green.withValues(alpha: 0.12) : Colors.deepOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isCompleted ? 'COMPLETED' : _isRunning ? 'ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isCompleted ? Colors.blue : _isRunning ? Colors.greenAccent.shade200 : Colors.deepOrangeAccent.shade200,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    //delete the timer 
                    widget.onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Timer'),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatTime(_remainingSeconds),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _getProgress(),
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatTime(_remainingSeconds)} remaining',
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color ?? colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '${(_getProgress() * 100).floor()}%',
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color ?? colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isCompleted ? _isRunning ? _pauseTimer : _startTimer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isRunning ? 'Pause' : 'Resume',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCompleted ? _undoCompleteTimer : _completeTimer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _isCompleted ? 'Undo' : 'Complete',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
