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

  TaskModel({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
  });
}
