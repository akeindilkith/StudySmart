import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_icons.dart';
import 'package:provider/provider.dart';
import '../models/subject.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/today_tasks_slider.dart';
import '../widgets/exam_countdown_card.dart';
import '../widgets/edit_note_dialog.dart';
import '../widgets/responsive_wrapper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedSubjectId;
  DateTime _currentCalendarMonth = DateTime.now();

  Subject? _findSubject(AppState appState, String noteId) {
    for (final sub in appState.userData?.subjects ?? []) {
      if (sub.notes.any((n) => n.id == noteId)) {
        return sub;
      }
    }
    return null;
  }

  // New Note quick entry form state
  final TextEditingController _noteContentController = TextEditingController();
  String? _formSubjectId;
  DateTime _formDate = DateTime.now();

  @override
  void dispose() {
    _noteContentController.dispose();
    super.dispose();
  }

  void _showAddTaskSheet(BuildContext context) {
    final appState = context.read<AppState>();
    final subjects = appState.userData?.subjects ?? [];
    if (subjects.isEmpty) return;

    _formDate = DateTime.now();
    _formSubjectId = (subjects.any((s) => s.id == _selectedSubjectId))
        ? _selectedSubjectId
        : subjects.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Add Study Note",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Subject", style: TextStyle(fontWeight: FontWeight.w600  )),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _formSubjectId,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    items: subjects.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _formSubjectId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Study Date", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _formDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => _formDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(DateFormat('MMMM d, yyyy').format(_formDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("What did you study / notes?", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteContentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "E.g. Thermodynamics laws and practice problems 1-10...",
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_noteContentController.text.trim().isNotEmpty && _formSubjectId != null) {
                          appState.addNote(
                            subjectId: _formSubjectId!,
                            content: _noteContentController.text.trim(),
                            studyDate: _formDate,
                          );
                          _noteContentController.clear();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Note added! Spaced review intervals calculated.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Schedule Review Reminders'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userData = appState.userData;

    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final subjects = userData.subjects;
    if (subjects.isNotEmpty && (_selectedSubjectId == null || !subjects.any((s) => s.id == _selectedSubjectId))) {
      _selectedSubjectId = subjects.first.id;
    }

    final selectedSubject = subjects.firstWhere(
      (s) => s.id == _selectedSubjectId,
      orElse: () => subjects.isNotEmpty ? subjects.first : Subject(id: '', name: ''),
    );

    final todayFormatted = DateFormat('EEEE, MMMM d').format(DateTime.now());

    // Generate days in current month for vertical calendar
    final year = _currentCalendarMonth.year;
    final month = _currentCalendarMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Scaffold(
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Gradient Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7E50FF), Color(0xFF111827)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayFormatted.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hi, ${userData.name}! 🚀',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(LucideIcons.bellRing, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Today's Tasks Slider
                  const TodayTasksSlider(),
                ],
              ),
            ),

            // Exam Countdown Card
            if (userData.exam != null)
              ExamCountdownCard(exam: userData.exam!),

            // Subject Selector Pills
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Subjects",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddTaskSheet(context),
                    icon: const Icon(LucideIcons.plusCircle, size: 16),
                    label: const Text('Add Note'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: subjects.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final isSelected = subject.id == _selectedSubjectId;

                  return ChoiceChip(
                    label: Text(
                      subject.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.foreground,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSubjectId = subject.id);
                      }
                    },
                  );
                },
              ),
            ),

            // Vertical Subject Study Calendar
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_currentCalendarMonth),
                    style: const TextStyle(
                      fontSize: 16,
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
                            _currentCalendarMonth = DateTime(
                              _currentCalendarMonth.year,
                              _currentCalendarMonth.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 20),
                        onPressed: () {
                          setState(() {
                            _currentCalendarMonth = DateTime(
                              _currentCalendarMonth.year,
                              _currentCalendarMonth.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Calendar sessions list
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: daysInMonth,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  final dayDate = DateTime(year, month, dayNumber);
                  final dayName = DateFormat('EEE').format(dayDate);
                  final fullDayName = DateFormat('EEEE').format(dayDate);
                  final isToday = dayDate.year == DateTime.now().year &&
                      dayDate.month == DateTime.now().month &&
                      dayDate.day == DateTime.now().day;

                  final isScheduledDay = selectedSubject.scheduledDays.contains(fullDayName);

                  final notesOnDay = selectedSubject.notes.where((note) {
                    final noteDate = DateTime.tryParse(note.date);
                    if (noteDate == null) return false;
                    return noteDate.year == year && noteDate.month == month && noteDate.day == dayNumber;
                  }).toList();

                  final remindersOnDay = selectedSubject.notes.where((note) {
                    return note.reminders.any((rem) {
                      final remDate = DateTime.tryParse(rem);
                      if (remDate == null) return false;
                      return remDate.year == year && remDate.month == month && remDate.day == dayNumber;
                    });
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day bubble
                        Container(
                          width: 44,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : isScheduledDay
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isToday ? Colors.white70 : AppColors.textMuted,
                                ),
                              ),
                              Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white : AppColors.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Sessions & Notes
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notesOnDay.isEmpty && remindersOnDay.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    isScheduledDay ? 'Regular study schedule' : 'No sessions scheduled',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isScheduledDay ? AppColors.primary : AppColors.textMuted,
                                      fontWeight: isScheduledDay ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              // Notes taken on this date
                              ...notesOnDay.map((n) {
                                return InkWell(
                                  onTap: () {
                                    final sub = _findSubject(appState, n.id);
                                    if (sub != null) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => EditNoteDialog(note: n, subject: sub),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.bookMarked, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            n.content,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        const Icon(LucideIcons.pencil, size: 12, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              // Spaced repetition reviews due on this date
                              ...remindersOnDay.map((n) {
                                final isDone = n.completedReminders.any((cr) {
                                  final crDate = DateTime.tryParse(cr);
                                  return crDate?.day == dayNumber && crDate?.month == month;
                                });

                                return InkWell(
                                  onTap: () {
                                    final sub = _findSubject(appState, n.id);
                                    if (sub != null) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => EditNoteDialog(note: n, subject: sub),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDone ? const Color(0xFFFEFCE8) : const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDone ? AppColors.completed : AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isDone ? LucideIcons.checkCircle2 : LucideIcons.repeat,
                                          size: 14,
                                          color: isDone ? Colors.amber[700] : AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Review: ${n.content}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDone ? Colors.amber[900] : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const Icon(LucideIcons.pencil, size: 12, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          onPressed: () => _showAddTaskSheet(context),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add Study Note', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
