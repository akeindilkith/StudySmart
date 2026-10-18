import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import 'package:provider/provider.dart';
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

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDay = 'Mon';
  final TextEditingController _todoInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _todoInputController.dispose();
    super.dispose();
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
        // Day Tabs
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
        // Slots list
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userData = appState.userData;
    final todos = userData?.todos ?? [];

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
        title: const Text('Schedule & Todos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs: Week vs Day
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
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

            // Tab Views - dynamically sized according to content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabController.index == 0
                  ? _buildWeekScheduleView(weekSchedule)
                  : _buildDayScheduleView(daySchedule),
            ),

            const SizedBox(height: 20),
            const Divider(indent: 20, endIndent: 20),
            const SizedBox(height: 12),

            // Todo List Section (Reorderable Draggable Items)
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

            // Todo Input field
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

            // Reorderable Todo List
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

            const SizedBox(height: 160), // Space for bottom nav dock
          ],
        ),
      ),
      ),
    );
  }
}
