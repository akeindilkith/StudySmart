import 'time_slot.dart';

class Schedule {
  final String id;
  String name;
  String type; // 'day' | 'week'
  List<TimeSlot>? timeSlots;
  Map<String, List<TimeSlot>>? week;

  Schedule({
    required this.id,
    required this.name,
    required this.type,
    this.timeSlots,
    this.week,
  });

  factory Schedule.defaultWeek({required String id, String name = 'My Week Schedule'}) {
    return Schedule(
      id: id,
      name: name,
      type: 'week',
      week: {
        'Mon': [],
        'Tue': [],
        'Wed': [],
        'Thu': [],
        'Fri': [],
        'Sat': [],
        'Sun': [],
      },
    );
  }

  factory Schedule.defaultDay({required String id, String name = 'My Day Schedule'}) {
    return Schedule(
      id: id,
      name: name,
      type: 'day',
      timeSlots: [],
    );
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    Map<String, List<TimeSlot>>? parsedWeek;
    if (json['week'] != null && json['week'] is Map) {
      parsedWeek = {};
      (json['week'] as Map).forEach((key, value) {
        final stringKey = key.toString();
        if (value is List) {
          parsedWeek![stringKey] = value
              .map((slot) {
                if (slot is Map<String, dynamic>) {
                  return TimeSlot.fromJson(slot);
                } else if (slot is Map) {
                  return TimeSlot.fromJson(Map<String, dynamic>.from(slot));
                }
                return null;
              })
              .whereType<TimeSlot>()
              .toList();
        } else {
          parsedWeek![stringKey] = [];
        }
      });
    }

    List<TimeSlot>? parsedSlots;
    if (json['timeSlots'] != null && json['timeSlots'] is List) {
      parsedSlots = (json['timeSlots'] as List<dynamic>)
          .map((slot) {
            if (slot is Map<String, dynamic>) {
              return TimeSlot.fromJson(slot);
            } else if (slot is Map) {
              return TimeSlot.fromJson(Map<String, dynamic>.from(slot));
            }
            return null;
          })
          .whereType<TimeSlot>()
          .toList();
    }

    return Schedule(
      id: json['id']?.toString() ?? 'sched-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Schedule',
      type: json['type'] as String? ?? 'week',
      timeSlots: parsedSlots ?? [],
      week: parsedWeek ?? {
        'Mon': [],
        'Tue': [],
        'Wed': [],
        'Thu': [],
        'Fri': [],
        'Sat': [],
        'Sun': [],
      },
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? weekJson;
    if (week != null) {
      weekJson = {};
      week!.forEach((key, list) {
        weekJson![key] = list.map((slot) => slot.toJson()).toList();
      });
    }

    return {
      'id': id,
      'name': name,
      'type': type,
      if (timeSlots != null) 'timeSlots': timeSlots!.map((s) => s.toJson()).toList(),
      if (weekJson != null) 'week': weekJson,
    };
  }
}
