import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskController extends GetxController {
  var tasks = <TaskModel>[].obs;
  late Box<TaskModel> taskBox;

  @override
  void onInit() {
    super.onInit();
    taskBox = Hive.box<TaskModel>('tasks');
    loadTasks();
  }

  void loadTasks() {
    tasks.value = taskBox.values.toList();
  }

  void addTask(TaskModel task) {
    taskBox.add(task);
    loadTasks();
  }

  void updateTask(int index, TaskModel updatedTask) {
    taskBox.putAt(index, updatedTask);
    loadTasks();
  }

  void deleteTask(int index) {
    taskBox.deleteAt(index);
    loadTasks();
  }

  void sortByPriority() {
    tasks.sort((a, b) => a.priority.compareTo(b.priority));
  }

  void sortByDueDate() {
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  void sortByCreatedAt() {
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<TaskModel> searchTasks(String query) {
    return tasks.where((task) =>
      task.title.toLowerCase().contains(query.toLowerCase()) ||
      task.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
