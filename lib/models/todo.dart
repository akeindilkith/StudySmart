class Todo {
  final String id;
  String task;
  bool completed;

  Todo({
    required this.id,
    required this.task,
    this.completed = false,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      task: json['task'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task': task,
      'completed': completed,
    };
  }

  Todo copyWith({
    String? id,
    String? task,
    bool? completed,
  }) {
    return Todo(
      id: id ?? this.id,
      task: task ?? this.task,
      completed: completed ?? this.completed,
    );
  }
}
