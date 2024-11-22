/// A data model representing a single task within a to-do list.
class Task {
  /// A unique identifier for the task.
  final String id;

  /// The title or description of the task.
  String title;

  /// Indicates whether the task is completed.
  bool completed;

  /// Creates a [Task].
  ///
  /// [id] The unique identifier.
  /// [title] The task title.
  /// [completed] The completion status.
  Task({
    required this.id,
    required this.title,
    this.completed = false,
  });

  /// Creates a copy of this [Task] with the given fields replaced with new values.
  ///
  /// [id] The new ID.
  /// [title] The new title.
  /// [completed] The new completion status.
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

  /// Constructs a [Task] from a JSON map.
  ///
  /// [json] The JSON map.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    completed: json['completed'],
  );

  /// Converts the [Task] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
  };
}

/// A data model representing a to-do list containing multiple tasks.
class ToDoList {
  /// A unique identifier for the to-do list.
  final String id;

  /// The name of the to-do list.
  String name;

  /// The creation date of the to-do list.
  final DateTime createdDate;

  /// A list of tasks within the to-do list.
  List<Task> tasks;

  /// Creates a [ToDoList].
  ///
  /// [id] The unique identifier.
  /// [name] The name of the list.
  /// [createdDate] The creation date.
  /// [tasks] The list of tasks.
  ToDoList({
    required this.id,
    required this.name,
    required this.createdDate,
    required this.tasks,
  });

  /// Constructs a [ToDoList] from a JSON map.
  ///
  /// [json] The JSON map.
  factory ToDoList.fromJson(Map<String, dynamic> json) => ToDoList(
    id: json['id'],
    name: json['name'],
    createdDate: DateTime.parse(json['createdDate']),
    tasks: (json['tasks'] as List<dynamic>)
        .map((taskJson) => Task.fromJson(taskJson))
        .toList(),
  );

  /// Converts the [ToDoList] to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdDate': createdDate.toIso8601String(),
    'tasks': tasks.map((task) => task.toJson()).toList(),
  };
}
