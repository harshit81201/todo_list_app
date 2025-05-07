import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String title;
  
  @HiveField(1)
  String description;
  
  @HiveField(2)
  int priority; // 1 = High, 2 = Medium, 3 = Low
  
  @HiveField(3)
  DateTime dueDate;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  bool isCompleted;

  TaskModel({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    this.isCompleted = false,
  });
  
  // Add a copyWith method to easily create modified copies
  TaskModel copyWith({
    String? title,
    String? description,
    int? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return TaskModel(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}