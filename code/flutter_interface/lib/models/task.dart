import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool localOnly;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.priority = 'medium',
    this.localOnly = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'localOnly': localOnly ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final localOnlyValue = map['localOnly'];
    int localOnlyInt = 0;
    if (localOnlyValue is bool) {
      localOnlyInt = localOnlyValue ? 1 : 0;
    } else if (localOnlyValue is num) {
      localOnlyInt = localOnlyValue.toInt();
    }
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      completed: map['completed'] == 1,
      priority: map['priority'] ?? 'medium',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      localOnly: (localOnlyInt == 1),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    bool? completed,
    String? priority,
    bool? localOnly,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt,
      localOnly: localOnly ?? this.localOnly,
    );
  }
}
