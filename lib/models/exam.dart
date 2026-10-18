class Exam {
  final String? name;
  final String date; // ISO-8601 string

  Exam({
    this.name,
    required this.date,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      name: json['name'] as String?,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'date': date,
    };
  }

  Exam copyWith({
    String? name,
    String? date,
  }) {
    return Exam(
      name: name ?? this.name,
      date: date ?? this.date,
    );
  }
}
