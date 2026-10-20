import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_icons.dart';
import '../models/time_slot.dart';
import '../models/schedule.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_wrapper.dart';

const List<String> kWeekDayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _scheduleTabController;
  String _selectedDay = 'Mon';
  final TextEditingController _todoInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _scheduleTabController = TabController(length: 2, vsync: this);

    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) {
        setState(() {});
      }
    });

    _scheduleTabController.addListener(() {
      if (!_scheduleTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _scheduleTabController.dispose();
    _todoInputController.dispose();
    super.dispose();
  }

  void _showWakeSleepTimeDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final userData = appState.userData;

    final wakeController = TextEditingController(text: userData?.wakeTime ?? '06:00');
    final sleepController = TextEditingController(text: userData?.sleepTime ?? '22:30');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Routine Schedule Setup', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please set your usual waking up and sleeping time to build your daily Time Management slots.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wakeController,
                decoration: const InputDecoration(
                  labelText: 'Getting Up Time (HH:mm)',
                  hintText: 'e.g. 05:30 or 06:00',
                  prefixIcon: Icon(LucideIcons.clock, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sleepController,
                decoration: const InputDecoration(
                  labelText: 'Sleeping Time (HH:mm)',
                  hintText: 'e.g. 22:30 or 23:00',
                  prefixIcon: Icon(LucideIcons.clock, size: 20),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final w = wakeController.text.trim();
                final s = sleepController.text.trim();
                if (w.isNotEmpty && s.isNotEmpty) {
                  appState.updateWakeSleepTimes(w, s);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save Routine'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTimeSlotDialog(BuildContext context, Schedule schedule, {String? day}) {
    final startTimeController = TextEditingController(text: '09:00 AM');
    final endTimeController = TextEditingController(text: '10:30 AM');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            day != null ? 'Add Slot ($day)' : 'Add Time Slot',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(labelText: 'End Time'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Activity / Subject Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.trim().isNotEmpty) {
                  final appState = context.read<AppState>();
                  appState.addTimeSlot(
                    scheduleId: schedule.id,
                    day: day,
                    startTime: startTimeController.text.trim(),
                    endTime: endTimeController.text.trim(),
                    note: noteController.text.trim(),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Slot'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSlotCard({
    required TimeSlot slot,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${slot.startTime} - ${slot.endTime}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              slot.note,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.missed),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekScheduleView(Schedule schedule) {
    final appState = context.watch<AppState>();
    final weekData = schedule.week ?? {};
    final daySlots = weekData[_selectedDay] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: kWeekDayShort.map((day) {
              final isSelected = day == _selectedDay;
              final count = (weekData[day] ?? []).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$day ($count)'),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.foreground,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedDay = day);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Time Slots for $_selectedDay",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showAddTimeSlotDialog(context, schedule, day: _selectedDay),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Slot'),
              ),
            ],
          ),
        ),
        if (daySlots.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.clock, size: 32, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No scheduled slots for $_selectedDay.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: daySlots.map((slot) {
                return _buildTimeSlotCard(
                  slot: slot,
                  onDelete: () {
                    appState.deleteTimeSlot(
                      scheduleId: schedule.id,
                      day: _selectedDay,
                      slotId: slot.id,
                    );
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDayScheduleView(Schedule schedule) {
    final appState = context.watch<AppState>();
    final slots = schedule.timeSlots ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daily Routine Slots",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showAddTimeSlotDialog(context, schedule),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Slot'),
              ),
            ],
          ),
        ),
        if (slots.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No daily slots created yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: slots.map((slot) {
                return _buildTimeSlotCard(
                  slot: slot,
                  onDelete: () {
                    appState.deleteTimeSlot(
                      scheduleId: schedule.id,
                      slotId: slot.id,
                    );
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTodosTab() {
    final appState = context.watch<AppState>();
    final todos = appState.userData?.todos ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.checkSquare, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Task & Todo List (${todos.where((t) => t.completed).length}/${todos.length})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _todoInputController,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      appState.addTodo(value.trim());
                      _todoInputController.clear();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "Add a quick task or todo item...",
                    prefixIcon: Icon(LucideIcons.listTodo, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  if (_todoInputController.text.trim().isNotEmpty) {
                    appState.addTodo(_todoInputController.text.trim());
                    _todoInputController.clear();
                  }
                },
                child: const Icon(LucideIcons.plus, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (todos.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                "No pending tasks! Add one above.",
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: todos.length,
              onReorderItem: (oldIndex, newIndex) {
                appState.reorderTodos(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final todo = todos[index];
                return Container(
                  key: ValueKey(todo.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Icon(LucideIcons.gripVertical, size: 18, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: todo.completed,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          appState.updateTodo(todo.id, completed: val ?? false);
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          todo.task,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: todo.completed ? TextDecoration.lineThrough : null,
                            color: todo.completed ? AppColors.textMuted : AppColors.foreground,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.missed),
                        onPressed: () {
                          appState.deleteTodo(todo.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleTab(Schedule weekSchedule, Schedule daySchedule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _scheduleTabController,
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.foreground,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: "Week Schedule"),
                Tab(text: "Day Schedule"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _scheduleTabController.index == 0
              ? _buildWeekScheduleView(weekSchedule)
              : _buildDayScheduleView(daySchedule),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userData = appState.userData;

    final schedules = userData?.schedules ?? [];
    final weekSchedule = schedules.firstWhere(
      (s) => s.type == 'week',
      orElse: () => Schedule.defaultWeek(id: 'default-week'),
    );
    final daySchedule = schedules.firstWhere(
      (s) => s.type == 'day',
      orElse: () => Schedule.defaultDay(id: 'default-day'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Topics TabBar: Time Management | Todos | Schedule
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _mainTabController,
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.foreground,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: "Time Mgmt"),
                      Tab(text: "Todos"),
                      Tab(text: "Schedule"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Tab Body
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _mainTabController.index == 0
                    ? _TimeManagementView(
                        onConfigureRoutine: () => _showWakeSleepTimeDialog(context),
                      )
                    : _mainTabController.index == 1
                        ? _buildTodosTab()
                        : _buildScheduleTab(weekSchedule, daySchedule),
              ),

              const SizedBox(height: 160), // Space for bottom nav dock
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeManagementView extends StatefulWidget {
  final VoidCallback onConfigureRoutine;

  const _TimeManagementView({required this.onConfigureRoutine});

  @override
  State<_TimeManagementView> createState() => _TimeManagementViewState();
}

class _TimeManagementViewState extends State<_TimeManagementView> {
  bool _isRunning = false;
  String _activeCategory = 'STUDY'; // 'STUDY', 'REST', 'WASTE'
  Timer? _ticker;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _elapsedSeconds++;
        });

        // Every 60 seconds, record 1 minute to the current active slot in AppState
        if (_elapsedSeconds > 0 && _elapsedSeconds % 60 == 0) {
          final now = DateTime.now();
          final currentMin = now.hour * 60 + now.minute;
          final appState = context.read<AppState>();
          final timeLog = appState.getOrCreateActiveTimeLog();

          for (final record in timeLog.records) {
            final slotParts = record.slotLabel.split('-');
            if (slotParts.length == 2) {
              final startMins = _parseMin(slotParts[0]);
              final endMins = _parseMin(slotParts[1]);

              if (currentMin >= startMins && currentMin < endMins) {
                appState.updateActiveSlotMinutes(record.slotLabel, _activeCategory, 1);
                break;
              }
            }
          }
        }
      });
    } else {
      _ticker?.cancel();
    }
  }

  int _parseMin(String timeStr) {
    final parts = timeStr.trim().split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0].trim()) ?? 0;
      final m = int.tryParse(parts[1].trim()) ?? 0;
      return h * 60 + m;
    }
    return 0;
  }

  String _formatTimerDisplay(int totalSeconds) {
    final hrs = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    final hStr = hrs.toString().padLeft(2, '0');
    final mStr = mins.toString().padLeft(2, '0');
    final sStr = secs.toString().padLeft(2, '0');
    return '$hStr:$mStr:$sStr';
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'STUDY':
        return const Color(0xFF10B981); // Emerald Green
      case 'REST':
        return AppColors.primary; // Purple
      case 'WASTE':
        return const Color(0xFFEF4444); // Amber Red
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final timeLog = appState.getOrCreateActiveTimeLog();
    final records = timeLog.records;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medium Start/Stop Timer Button & Live Ticker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isRunning
                    ? [_getCategoryColor(_activeCategory), _getCategoryColor(_activeCategory).withValues(alpha: 0.8)]
                    : [AppColors.foreground, AppColors.foreground.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _getCategoryColor(_activeCategory).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _isRunning ? 'ACTIVE TRACKING ($_activeCategory)' : 'TIMER PAUSED',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimerDisplay(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFeatures: [],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _isRunning ? AppColors.missed : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _toggleTimer,
                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    _isRunning ? 'STOP TRACKER' : 'START TRACKER',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Modern 3-Button Toggle: STUDY | REST | WASTE
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildCategoryButton('STUDY', LucideIcons.bookOpen, const Color(0xFF10B981)),
                _buildCategoryButton('REST', LucideIcons.coffee, const Color(0xFF7E50FF)),
                _buildCategoryButton('WASTE', LucideIcons.alertTriangle, const Color(0xFFEF4444)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5-Column Table: Blank/Time | STUDY | REST | WASTE | REASON
          const Text(
            'Daily Slot Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.foreground),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('STUDY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981)))),
                  DataColumn(label: Text('REST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7E50FF)))),
                  DataColumn(label: Text('WASTE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFEF4444)))),
                  DataColumn(label: Text('Reason for wasting time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: records.map((record) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          record.slotLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${record.studyMinutes}m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: record.studyMinutes > 0 ? FontWeight.bold : FontWeight.normal,
                            color: record.studyMinutes > 0 ? const Color(0xFF10B981) : AppColors.textMuted,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${record.restMinutes}m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: record.restMinutes > 0 ? FontWeight.bold : FontWeight.normal,
                            color: record.restMinutes > 0 ? const Color(0xFF7E50FF) : AppColors.textMuted,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${record.wasteMinutes}m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: record.wasteMinutes > 0 ? FontWeight.bold : FontWeight.normal,
                            color: record.wasteMinutes > 0 ? const Color(0xFFEF4444) : AppColors.textMuted,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: TextEditingController(text: record.reason)
                              ..selection = TextSelection.collapsed(offset: record.reason.length),
                            style: const TextStyle(fontSize: 11),
                            decoration: const InputDecoration(
                              hintText: 'Add reason...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              appState.updateActiveSlotReason(record.slotLabel, val);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Clear All and Save Records Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Save & Clear Log', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Save today\'s Time Management record into history logs and reset the active table?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            appState.saveAndClearTimeLog();
                            setState(() {
                              _elapsedSeconds = 0;
                              _isRunning = false;
                            });
                            _ticker?.cancel();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Time Management log saved to history!')),
                            );
                          },
                          child: const Text('Save & Reset'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(LucideIcons.database, size: 18, color: AppColors.primary),
              label: const Text('Clear All and Save Records', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 20),

          // Routine Info Banner with Edit Button (at the end)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Routine Window',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Wake: ${timeLog.wakeTime}  •  Sleep: ${timeLog.sleepTime}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.foreground),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: widget.onConfigureRoutine,
                  icon: const Icon(LucideIcons.pencil, size: 14),
                  label: const Text('Edit Routine'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category, IconData icon, Color color) {
    final isSelected = _activeCategory == category;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                child: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.foreground,
                ),
                child: Text(category),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
