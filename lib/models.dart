class Task {
  final String id;
  final String title;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.completed,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    completed: json['completed'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };
}

class ToDoList {
  final String id;
  String name;
  final DateTime createdDate;
  List<Task> tasks;

  ToDoList({
    required this.id,
    required this.name,
    required this.createdDate,
    required this.tasks,
  });

  factory ToDoList.fromJson(Map<String, dynamic> json) => ToDoList(
    id: json['id'],
    name: json['listName'],
    createdDate: DateTime.parse(json['createdDate']),
    tasks: (json['tasks'] as List<dynamic>)
        .map((taskJson) => Task.fromJson(taskJson))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'listName': name,
    'createdDate': createdDate.toIso8601String(),
    'tasks': tasks.map((task) => task.toJson()).toList(),
  };
}
