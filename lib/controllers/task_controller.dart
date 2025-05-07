import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

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
    scheduleReminder(task, tasks.length - 1); // use index as ID
  }

  void updateTask(int index, TaskModel updatedTask) {
    tasks[index] = updatedTask;
    _box.putAt(index, updatedTask);
    NotificationService.cancelNotification(index);
    scheduleReminder(updatedTask, index);
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
    return tasks
        .where(
          (task) =>
              task.title.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  void scheduleReminder(TaskModel task, int id) {
    if (task.dueDate.isAfter(DateTime.now())) {
      NotificationService.scheduleNotification(
        id: id,
        title: 'Task Reminder',
        body: '${task.title} is due soon!',
        scheduledDate: task.dueDate.subtract(const Duration(minutes: 10)),
      );
    }
  }
}
