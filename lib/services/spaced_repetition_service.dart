import '../models/note.dart';
import '../models/user_data.dart';

class SpacedRepetitionService {
  /// Parses pattern strings like "3, 6, 14, 30*12" into List<int>
  static List<int> parsePatternString(String patternStr) {
    if (patternStr.trim().isEmpty) {
      return [3, 6, 14, 30];
    }

    final List<int> result = [];
    final parts = patternStr.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('*')) {
        final subParts = trimmed.split('*');
        if (subParts.length == 2) {
          final num = int.tryParse(subParts[0].trim());
          final count = int.tryParse(subParts[1].trim());
          if (num != null && num > 0 && count != null && count > 0) {
            for (int i = 1; i <= count; i++) {
              result.add(num * i);
            }
          }
        }
      } else {
        final num = int.tryParse(trimmed);
        if (num != null && num > 0) {
          result.add(num);
        }
      }
    }

    // Sort ascending and remove duplicates
    final uniqueSorted = result.toSet().toList()..sort();
    return uniqueSorted.isEmpty ? [3, 6, 14, 30] : uniqueSorted;
  }

  /// Calculates upcoming reminder ISO strings for a given base study date
  static List<String> calculateReminderDates(DateTime baseDate, List<int> pattern) {
    final List<String> reminders = [];
    for (final days in pattern) {
      final reminderDate = baseDate.add(Duration(days: days));
      // Store in ISO format: YYYY-MM-DD
      final isoString = reminderDate.toIso8601String().split('T').first;
      reminders.add(isoString);
    }
    return reminders;
  }

  /// Evaluates all notes in UserData, identifying and moving past uncompleted reminders to missed
  static UserData syncMissedReminders(UserData data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool modified = false;

    for (final subject in data.subjects) {
      for (final note in subject.notes) {
        final List<String> updatedMissed = List.from(note.missedReminders);

        for (final reminderStr in note.reminders) {
          final reminderDate = DateTime.tryParse(reminderStr);
          if (reminderDate == null) continue;

          final reminderDay = DateTime(reminderDate.year, reminderDate.month, reminderDate.day);

          if (reminderDay.isBefore(today)) {
            final isCompleted = note.completedReminders.any((cr) {
              final crDate = DateTime.tryParse(cr);
              if (crDate == null) return false;
              return crDate.year == reminderDate.year &&
                  crDate.month == reminderDate.month &&
                  crDate.day == reminderDate.day;
            });

            final isAlreadyMissed = updatedMissed.any((mr) {
              final mrDate = DateTime.tryParse(mr);
              if (mrDate == null) return false;
              return mrDate.year == reminderDate.year &&
                  mrDate.month == reminderDate.month &&
                  mrDate.day == reminderDate.day;
            });

            if (!isCompleted && !isAlreadyMissed) {
              updatedMissed.add(reminderStr);
              modified = true;
            }
          }
        }

        if (modified) {
          note.missedReminders = updatedMissed;
        }
      }
    }

    return data;
  }

  /// Checks if a note has a reminder scheduled for a specific date
  static bool hasReminderOnDay(Note note, DateTime day) {
    final dateStr = day.toIso8601String().split('T').first;
    return note.reminders.contains(dateStr);
  }

  /// Checks if a note has a completed reminder on a specific date
  static bool hasCompletedOnDay(Note note, DateTime day) {
    final dateStr = day.toIso8601String().split('T').first;
    return note.completedReminders.contains(dateStr);
  }

  /// Checks if a note has a missed reminder on a specific date
  static bool hasMissedOnDay(Note note, DateTime day) {
    final dateStr = day.toIso8601String().split('T').first;
    return note.missedReminders.contains(dateStr);
  }
}
