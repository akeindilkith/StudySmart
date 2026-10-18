import 'note.dart';

class Subject {
  final String id;
  String name;
  List<String> scheduledDays; // e.g. ["Monday", "Wednesday"]
  List<Note> notes;

  Subject({
    required this.id,
    required this.name,
    List<String>? scheduledDays,
    List<Note>? notes,
  })  : scheduledDays = scheduledDays ?? [],
        notes = notes ?? [];

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Subject',
      scheduledDays: (json['scheduledDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return Note.fromJson(e);
                } else if (e is Map) {
                  return Note.fromJson(Map<String, dynamic>.from(e));
                }
                return null;
              })
              .whereType<Note>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scheduledDays': scheduledDays,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }

  Subject copyWith({
    String? id,
    String? name,
    List<String>? scheduledDays,
    List<Note>? notes,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      scheduledDays: scheduledDays ?? List.from(this.scheduledDays),
      notes: notes ?? List.from(this.notes),
    );
  }
}
