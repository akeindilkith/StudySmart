import 'subject.dart';
import 'schedule.dart';
import 'exam.dart';
import 'todo.dart';

class UserData {
  String name;
  List<Subject> subjects;
  List<int> reminderPattern;
  List<Schedule>? schedules;
  Exam? exam;
  List<Todo>? todos;

  UserData({
    required this.name,
    required this.subjects,
    required this.reminderPattern,
    this.schedules,
    this.exam,
    this.todos,
  });

  factory UserData.initial({String name = 'Student'}) {
    return UserData(
      name: name,
      subjects: [],
      reminderPattern: [3, 6, 14, 30],
      schedules: [
        Schedule.defaultWeek(
          id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
          name: 'My Week Schedule',
        ),
      ],
      todos: [],
    );
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] as String? ?? 'User',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((s) {
                if (s is Map<String, dynamic>) {
                  return Subject.fromJson(s);
                } else if (s is Map) {
                  return Subject.fromJson(Map<String, dynamic>.from(s));
                }
                return null;
              })
              .whereType<Subject>()
              .toList() ??
          [],
      reminderPattern: (json['reminderPattern'] as List<dynamic>?)
              ?.map((p) => (p as num).toInt())
              .toList() ??
          [3, 6, 14, 30],
      schedules: (json['schedules'] as List<dynamic>?)
          ?.map((s) {
            if (s is Map<String, dynamic>) {
              return Schedule.fromJson(s);
            } else if (s is Map) {
              return Schedule.fromJson(Map<String, dynamic>.from(s));
            }
            return null;
          })
          .whereType<Schedule>()
          .toList(),
      exam: json['exam'] != null
          ? (json['exam'] is Map<String, dynamic>
              ? Exam.fromJson(json['exam'] as Map<String, dynamic>)
              : json['exam'] is Map
                  ? Exam.fromJson(Map<String, dynamic>.from(json['exam'] as Map))
                  : null)
          : null,
      todos: (json['todos'] as List<dynamic>?)
          ?.map((t) {
            if (t is Map<String, dynamic>) {
              return Todo.fromJson(t);
            } else if (t is Map) {
              return Todo.fromJson(Map<String, dynamic>.from(t));
            }
            return null;
          })
          .whereType<Todo>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'reminderPattern': reminderPattern,
      if (schedules != null)
        'schedules': schedules!.map((s) => s.toJson()).toList(),
      if (exam != null) 'exam': exam!.toJson(),
      if (todos != null) 'todos': todos!.map((t) => t.toJson()).toList(),
    };
  }

  UserData copyWith({
    String? name,
    List<Subject>? subjects,
    List<int>? reminderPattern,
    List<Schedule>? schedules,
    Exam? exam,
    List<Todo>? todos,
  }) {
    return UserData(
      name: name ?? this.name,
      subjects: subjects ?? this.subjects,
      reminderPattern: reminderPattern ?? this.reminderPattern,
      schedules: schedules ?? this.schedules,
      exam: exam ?? this.exam,
      todos: todos ?? this.todos,
    );
  }
}
