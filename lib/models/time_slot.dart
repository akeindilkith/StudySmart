class TimeSlot {
  final String id;
  String startTime;
  String endTime;
  String note;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.note,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      startTime: json['startTime'] as String? ?? '09:00',
      endTime: json['endTime'] as String? ?? '10:00',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'note': note,
    };
  }

  TimeSlot copyWith({
    String? id,
    String? startTime,
    String? endTime,
    String? note,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
    );
  }
}
