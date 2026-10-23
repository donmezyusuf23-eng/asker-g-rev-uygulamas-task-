import 'dart:convert';

enum TaskPriority { low, medium, high }

enum RepeatInterval { none, daily, weekly, monthly }

class SubTask {
  final String id;
  String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class TaskItem {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  DateTime? reminderTime;
  TaskPriority priority;
  String category;
  String projectId;
  bool isCompleted;
  DateTime? completedAt;
  DateTime createdAt;
  List<SubTask> subtasks;
  bool isTopPriority; // Günün en önemli 3 görevinden biri mi
  RepeatInterval repeatInterval;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.reminderTime,
    this.priority = TaskPriority.medium,
    this.category = 'Kişisel',
    this.projectId = 'personal',
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
    List<SubTask>? subtasks,
    this.isTopPriority = false,
    this.repeatInterval = RepeatInterval.none,
  })  : createdAt = createdAt ?? DateTime.now(),
        subtasks = subtasks ?? [];

  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.isBefore(now);
  }

  bool isDueToday() {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool isDueTomorrow() {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'priority': priority.index,
      'category': category,
      'projectId': projectId,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'isTopPriority': isTopPriority,
      'repeatInterval': repeatInterval.index,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'])
          : null,
      priority: TaskPriority.values[map['priority'] ?? 1],
      category: map['category'] ?? 'Kişisel',
      projectId: map['projectId'] ?? 'personal',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((s) => SubTask.fromMap(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      isTopPriority: map['isTopPriority'] ?? false,
      repeatInterval: RepeatInterval.values[map['repeatInterval'] ?? 0],
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskItem.fromJson(String source) =>
      TaskItem.fromMap(json.decode(source));

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    TaskPriority? priority,
    String? category,
    String? projectId,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    List<SubTask>? subtasks,
    bool? isTopPriority,
    RepeatInterval? repeatInterval,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      projectId: projectId ?? this.projectId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      subtasks: subtasks ?? this.subtasks.map((s) => SubTask(id: s.id, title: s.title, isCompleted: s.isCompleted)).toList(),
      isTopPriority: isTopPriority ?? this.isTopPriority,
      repeatInterval: repeatInterval ?? this.repeatInterval,
    );
  }
}
