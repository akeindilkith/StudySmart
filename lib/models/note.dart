class Note {
  final String id;
  String date; // ISO-8601 string
  String content;
  List<String> reminders; // ISO strings of scheduled review dates
  List<String> completedReminders;
  List<String> missedReminders;

  Note({
    required this.id,
    required this.date,
    required this.content,
    List<String>? reminders,
    List<String>? completedReminders,
    List<String>? missedReminders,
  })  : reminders = reminders ?? [],
        completedReminders = completedReminders ?? [],
        missedReminders = missedReminders ?? [];

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      date: json['date'] as String,
      content: json['content'] as String? ?? '',
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completedReminders: (json['completedReminders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missedReminders: (json['missedReminders'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'content': content,
      'reminders': reminders,
      'completedReminders': completedReminders,
      'missedReminders': missedReminders,
    };
  }

  Note copyWith({
    String? id,
    String? date,
    String? content,
    List<String>? reminders,
    List<String>? completedReminders,
    List<String>? missedReminders,
  }) {
    return Note(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      reminders: reminders ?? List.from(this.reminders),
      completedReminders: completedReminders ?? List.from(this.completedReminders),
      missedReminders: missedReminders ?? List.from(this.missedReminders),
    );
  }
}
