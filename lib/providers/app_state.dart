import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_data.dart';
import '../models/subject.dart';
import '../models/note.dart';
import '../models/schedule.dart';
import '../models/time_slot.dart';
import '../models/todo.dart';
import '../models/exam.dart';
import '../services/local_storage_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/notification_service.dart';

class TaskItem {
  final Note note;
  final Subject subject;

  TaskItem({required this.note, required this.subject});
}

class AppState extends ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  final Uuid _uuid = const Uuid();

  UserData? _userData;
  bool _isLoading = true;

  UserData? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isOnboardingCompleted => _userData != null && _userData!.subjects.isNotEmpty;

  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final data = await _storageService.loadUserData();
    if (data != null) {
      _userData = SpacedRepetitionService.syncMissedReminders(data);
      await _storageService.saveUserData(_userData!);
      await NotificationService.instance.syncReviewNotifications(_userData);
    } else {
      _userData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_userData != null) {
      await _storageService.saveUserData(_userData!);
      await NotificationService.instance.syncReviewNotifications(_userData);
    }
    notifyListeners();
  }

  // --- Onboarding ---
  Future<void> completeOnboarding({
    required String name,
    required List<String> subjectNames,
    required Map<String, List<String>> subjectDays,
    DateTime? examDate,
  }) async {
    final List<Subject> subjects = [];
    for (final subName in subjectNames) {
      final id = 'sub-${_uuid.v4()}';
      subjects.add(
        Subject(
          id: id,
          name: subName,
          scheduledDays: subjectDays[subName] ?? [],
          notes: [],
        ),
      );
    }

    final newUserData = UserData(
      name: name.trim().isEmpty ? 'Student' : name.trim(),
      subjects: subjects,
      reminderPattern: [3, 6, 14, 30],
      exam: examDate != null ? Exam(name: 'Final Exam', date: examDate.toIso8601String()) : null,
      schedules: [
        Schedule.defaultWeek(
          id: 'sched-${_uuid.v4()}',
          name: 'My Week Schedule',
        ),
      ],
      todos: [
        Todo(id: 'todo-${_uuid.v4()}', task: 'Review notes regularly', completed: false),
        Todo(id: 'todo-${_uuid.v4()}', task: 'Prepare study flashcards', completed: false),
      ],
    );

    _userData = newUserData;
    await _persist();
  }

  // --- Profile & Exam ---
  Future<void> updateUserName(String name) async {
    if (_userData == null) return;
    _userData!.name = name;
    await _persist();
  }

  Future<void> updateExam(String? name, DateTime date) async {
    if (_userData == null) return;
    _userData!.exam = Exam(
      name: name ?? _userData!.exam?.name ?? 'Exam',
      date: date.toIso8601String(),
    );
    await _persist();
  }

  Future<void> clearExam() async {
    if (_userData == null) return;
    _userData!.exam = null;
    await _persist();
  }

  // --- Spaced Repetition Pattern ---
  Future<void> updateReminderPattern(List<int> pattern) async {
    if (_userData == null) return;
    _userData!.reminderPattern = pattern;
    await _persist();
  }

  // --- Subjects ---
  Future<void> addSubject(String name) async {
    if (_userData == null || name.trim().isEmpty) return;
    if (_userData!.subjects.any((s) => s.name.toLowerCase() == name.trim().toLowerCase())) {
      return;
    }
    final newSubject = Subject(
      id: 'sub-${_uuid.v4()}',
      name: name.trim(),
      scheduledDays: [],
      notes: [],
    );
    _userData!.subjects.add(newSubject);
    await _persist();
  }

  Future<void> removeSubject(String subjectId) async {
    if (_userData == null) return;
    _userData!.subjects.removeWhere((s) => s.id == subjectId);
    await _persist();
  }

  Future<void> updateSubjectDays(String subjectId, List<String> days) async {
    if (_userData == null) return;
    final subject = _userData!.subjects.firstWhere((s) => s.id == subjectId, orElse: () => _userData!.subjects.first);
    subject.scheduledDays = days;
    await _persist();
  }

  // --- Notes & Spaced Repetition ---
  Future<void> addNote({
    required String subjectId,
    required String content,
    required DateTime studyDate,
  }) async {
    if (_userData == null || content.trim().isEmpty) return;

    final subjectIndex = _userData!.subjects.indexWhere((s) => s.id == subjectId);
    if (subjectIndex == -1) return;

    final pattern = _userData!.reminderPattern.isNotEmpty ? _userData!.reminderPattern : [3, 6, 14, 30];
    final reminders = SpacedRepetitionService.calculateReminderDates(studyDate, pattern);

    final newNote = Note(
      id: 'note-${_uuid.v4()}',
      date: studyDate.toIso8601String(),
      content: content.trim(),
      reminders: reminders,
      completedReminders: [],
      missedReminders: [],
    );

    _userData!.subjects[subjectIndex].notes.add(newNote);
    await _persist();
  }

  Future<void> deleteNote(String subjectId, String noteId) async {
    if (_userData == null) return;
    final subject = _userData!.subjects.firstWhere((s) => s.id == subjectId, orElse: () => _userData!.subjects.first);
    subject.notes.removeWhere((n) => n.id == noteId);
    await _persist();
  }

  Future<void> deleteNoteById(String noteId) async {
    if (_userData == null) return;

    for (final subject in _userData!.subjects) {
      subject.notes.removeWhere((n) => n.id == noteId);
    }
    await _persist();
  }

  Future<void> updateNote({
    required String noteId,
    required String newContent,
    required DateTime newStudyDate,
  }) async {
    if (_userData == null || newContent.trim().isEmpty) return;

    final pattern = _userData!.reminderPattern.isNotEmpty ? _userData!.reminderPattern : [3, 6, 14, 30];
    final reminders = SpacedRepetitionService.calculateReminderDates(newStudyDate, pattern);

    for (final subject in _userData!.subjects) {
      final noteIndex = subject.notes.indexWhere((n) => n.id == noteId);
      if (noteIndex != -1) {
        final note = subject.notes[noteIndex];
        note.content = newContent.trim();
        note.date = newStudyDate.toIso8601String();
        note.reminders = reminders;
        await _persist();
        return;
      }
    }
  }

  Future<void> markReminderDone(String noteId, DateTime date) async {
    if (_userData == null) return;
    final dateStr = date.toIso8601String().split('T').first;

    for (final subject in _userData!.subjects) {
      for (final note in subject.notes) {
        if (note.id == noteId) {
          final isAlreadyDone = note.completedReminders.any((cr) {
            final crDate = DateTime.tryParse(cr);
            return crDate != null &&
                crDate.year == date.year &&
                crDate.month == date.month &&
                crDate.day == date.day;
          });
          if (!isAlreadyDone) {
            note.completedReminders.add(dateStr);
          }
          note.missedReminders.removeWhere((mr) {
            final mrDate = DateTime.tryParse(mr);
            return mrDate != null &&
                mrDate.year == date.year &&
                mrDate.month == date.month &&
                mrDate.day == date.day;
          });
          await _persist();
          return;
        }
      }
    }
  }

  Future<void> undoReminderDone(String noteId, DateTime date) async {
    if (_userData == null) return;

    for (final subject in _userData!.subjects) {
      for (final note in subject.notes) {
        if (note.id == noteId) {
          note.completedReminders.removeWhere((cr) {
            final crDate = DateTime.tryParse(cr);
            return crDate != null &&
                crDate.year == date.year &&
                crDate.month == date.month &&
                crDate.day == date.day;
          });
          await _persist();
          return;
        }
      }
    }
  }

  Future<void> markMissedAsDone(String noteId, DateTime date) async {
    if (_userData == null) return;
    final dateStr = date.toIso8601String().split('T').first;

    for (final subject in _userData!.subjects) {
      for (final note in subject.notes) {
        if (note.id == noteId) {
          note.missedReminders.removeWhere((mr) {
            final mrDate = DateTime.tryParse(mr);
            return mrDate != null &&
                mrDate.year == date.year &&
                mrDate.month == date.month &&
                mrDate.day == date.day;
          });
          final isAlreadyDone = note.completedReminders.any((cr) {
            final crDate = DateTime.tryParse(cr);
            return crDate != null &&
                crDate.year == date.year &&
                crDate.month == date.month &&
                crDate.day == date.day;
          });
          if (!isAlreadyDone) {
            note.completedReminders.add(dateStr);
          }
          await _persist();
          return;
        }
      }
    }
  }

  // --- Today's Tasks ---
  List<TaskItem> get todaysTasks {
    if (_userData == null) return [];
    final now = DateTime.now();

    final List<TaskItem> tasks = [];
    for (final subject in _userData!.subjects) {
      for (final note in subject.notes) {
        final isDueToday = note.reminders.any((r) {
          final rDate = DateTime.tryParse(r);
          return rDate != null &&
              rDate.year == now.year &&
              rDate.month == now.month &&
              rDate.day == now.day;
        });

        if (isDueToday) {
          final isCompletedToday = note.completedReminders.any((cr) {
            final crDate = DateTime.tryParse(cr);
            return crDate != null &&
                crDate.year == now.year &&
                crDate.month == now.month &&
                crDate.day == now.day;
          });

          if (!isCompletedToday) {
            tasks.add(TaskItem(note: note, subject: subject));
          }
        }
      }
    }
    return tasks;
  }

  // --- Todos ---
  Future<void> addTodo(String task) async {
    if (_userData == null || task.trim().isEmpty) return;
    _userData!.todos ??= [];
    _userData!.todos!.add(
      Todo(
        id: 'todo-${_uuid.v4()}',
        task: task.trim(),
        completed: false,
      ),
    );
    await _persist();
  }

  Future<void> updateTodo(String id, {String? task, bool? completed}) async {
    if (_userData == null || _userData!.todos == null) return;
    final index = _userData!.todos!.indexWhere((t) => t.id == id);
    if (index != -1) {
      if (task != null) _userData!.todos![index].task = task;
      if (completed != null) _userData!.todos![index].completed = completed;
      await _persist();
    }
  }

  Future<void> deleteTodo(String id) async {
    if (_userData == null || _userData!.todos == null) return;
    _userData!.todos!.removeWhere((t) => t.id == id);
    await _persist();
  }

  Future<void> reorderTodos(int oldIndex, int newIndex) async {
    if (_userData == null || _userData!.todos == null) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _userData!.todos!.removeAt(oldIndex);
    _userData!.todos!.insert(newIndex, item);
    await _persist();
  }

  // --- Schedules ---
  Future<void> addSchedule({required String name, required String type}) async {
    if (_userData == null) return;
    _userData!.schedules ??= [];
    final newSchedule = type == 'week'
        ? Schedule.defaultWeek(id: 'sched-${_uuid.v4()}', name: name)
        : Schedule.defaultDay(id: 'sched-${_uuid.v4()}', name: name);
    _userData!.schedules!.add(newSchedule);
    await _persist();
  }

  Future<void> deleteSchedule(String id) async {
    if (_userData == null || _userData!.schedules == null) return;
    _userData!.schedules!.removeWhere((s) => s.id == id);
    await _persist();
  }

  Future<void> addTimeSlot({
    required String scheduleId,
    String? day,
    required String startTime,
    required String endTime,
    required String note,
  }) async {
    if (_userData == null || _userData!.schedules == null) return;
    final schedule = _userData!.schedules!.firstWhere((s) => s.id == scheduleId);

    final slot = TimeSlot(
      id: 'slot-${_uuid.v4()}',
      startTime: startTime,
      endTime: endTime,
      note: note,
    );

    if (schedule.type == 'week' && day != null) {
      schedule.week ??= {};
      schedule.week![day] ??= [];
      schedule.week![day]!.add(slot);
    } else {
      schedule.timeSlots ??= [];
      schedule.timeSlots!.add(slot);
    }

    await _persist();
  }

  Future<void> deleteTimeSlot({
    required String scheduleId,
    String? day,
    required String slotId,
  }) async {
    if (_userData == null || _userData!.schedules == null) return;
    final schedule = _userData!.schedules!.firstWhere((s) => s.id == scheduleId);

    if (schedule.type == 'week' && day != null && schedule.week != null) {
      schedule.week![day]?.removeWhere((s) => s.id == slotId);
    } else if (schedule.timeSlots != null) {
      schedule.timeSlots!.removeWhere((s) => s.id == slotId);
    }

    await _persist();
  }

  // --- Reset All Data ---
  Future<void> resetAllData() async {
    await _storageService.clearUserData();
    await NotificationService.instance.cancelAll();
    _userData = null;
    notifyListeners();
  }
}
