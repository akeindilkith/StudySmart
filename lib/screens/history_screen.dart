import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/history_day_detail_dialog.dart';
import '../widgets/responsive_wrapper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedMonth = DateTime.now();

  List<Map<String, dynamic>> _getNotesForDay(DateTime day, AppState appState) {
    final userData = appState.userData;
    if (userData == null) return [];

    final List<Map<String, dynamic>> result = [];

    for (final subject in userData.subjects) {
      for (final note in subject.notes) {
        final isCompleted = note.completedReminders.any((cr) {
          final d = DateTime.tryParse(cr);
          return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
        });
        final isMissed = note.missedReminders.any((mr) {
          final d = DateTime.tryParse(mr);
          return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
        });
        final isScheduled = note.reminders.any((r) {
          final d = DateTime.tryParse(r);
          return d != null && d.year == day.year && d.month == day.month && d.day == day.day;
        });

        if (isCompleted || isMissed || isScheduled) {
          String status = 'scheduled';
          if (isCompleted) {
            status = 'completed';
          } else if (isMissed) {
            status = 'missed';
          }

          result.add({
            'note': note,
            'subject': subject,
            'status': status,
          });
        }
      }
    }
    return result;
  }

  void _onDayTapped(DateTime day, AppState appState) {
    final items = _getNotesForDay(day, appState);
    if (items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => HistoryDayDetailDialog(date: day, items: items),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No spaced review sessions logged on ${DateFormat('MMM d').format(day)}.'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = (firstDayOfMonth.weekday % 7); // 0 = Sunday, 1 = Monday, etc.

    // Statistics
    int totalCompleted = 0;
    int totalMissed = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final items = _getNotesForDay(DateTime(year, month, d), appState);
      for (final item in items) {
        if (item['status'] == 'completed') totalCompleted++;
        if (item['status'] == 'missed') totalMissed++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study History Log', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight, size: 20),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overview stats banner
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.completed.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.star, color: Colors.amber, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalCompleted',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Completed',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.missed.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.x, color: AppColors.missed, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalMissed',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Missed',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Calendar Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Weekday headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) {
                      return SizedBox(
                        width: 36,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: startingWeekday + daysInMonth,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      if (index < startingWeekday) {
                        return const SizedBox();
                      }

                      final dayNumber = index - startingWeekday + 1;
                      final dayDate = DateTime(year, month, dayNumber);
                      final isToday = dayDate.year == DateTime.now().year &&
                          dayDate.month == DateTime.now().month &&
                          dayDate.day == DateTime.now().day;

                      final dayItems = _getNotesForDay(dayDate, appState);
                      final hasCompleted = dayItems.any((i) => i['status'] == 'completed');
                      final hasMissed = dayItems.any((i) => i['status'] == 'missed');
                      final hasScheduled = dayItems.any((i) => i['status'] == 'scheduled');

                      Widget? statusBadge;
                      if (hasCompleted && !hasMissed && !hasScheduled) {
                        // All completed: Star icon
                        statusBadge = const Icon(LucideIcons.star, size: 10, color: Colors.amber);
                      } else if (hasMissed && !hasCompleted) {
                        // All missed: X icon
                        statusBadge = const Icon(LucideIcons.x, size: 10, color: AppColors.missed);
                      } else if (dayItems.isNotEmpty) {
                        // Mixed: Dot icon
                        statusBadge = Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.mixed,
                            shape: BoxShape.circle,
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () => _onDayTapped(dayDate, appState),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : dayItems.isNotEmpty
                                    ? const Color(0xFFF9FAFB)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isToday
                                  ? AppColors.primary
                                  : dayItems.isNotEmpty
                                      ? AppColors.border
                                      : Colors.transparent,
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                  color: isToday ? AppColors.primary : AppColors.foreground,
                                ),
                              ),
                              if (statusBadge != null) ...[
                                const SizedBox(height: 2),
                                statusBadge,
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Legend
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 6),
                      Text('Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(LucideIcons.x, size: 14, color: AppColors.missed),
                      SizedBox(width: 6),
                      Text('Missed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.mixed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Mixed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 160),
          ],
        ),
      ),
      ),
    );
  }
}
