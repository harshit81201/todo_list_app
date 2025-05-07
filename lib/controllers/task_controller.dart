import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

class TaskController extends GetxController {
  var tasks = <TaskModel>[].obs;
  Box<TaskModel>? taskBox;
  var filteredTasks = <TaskModel>[].obs;
  var searchQuery = ''.obs;
  var sortOption = 'Creation Date'.obs;

  @override
  void onInit() {
    super.onInit();
    taskBox = Hive.box<TaskModel>("taskbox"); // ✅ Initialize the box
    loadTasks();
    filteredTasks.assignAll(tasks);
  }

  void loadTasks() {
    tasks.value = taskBox?.values.toList() ?? [];
    filteredTasks.assignAll(tasks); // ✅ Keep both in sync
  }

  void addTask(TaskModel task) {
    tasks.add(task);
    taskBox?.add(task);
    scheduleReminder(task, tasks.length - 1);
    filteredTasks.assignAll(tasks); // ✅ This line fixes your issue
  }

  void updateTask(int index, TaskModel updatedTask) {
    if (index < 0 || index >= tasks.length) return; // Safeguard
    tasks[index] = updatedTask;
    taskBox?.putAt(index, updatedTask);
    NotificationService.cancelNotification(index);
    scheduleReminder(updatedTask, index);

    // Reflect changes in filteredTasks as well
    searchTasks(searchQuery.value); // This re-filters based on current search
  }

  void deleteTask(int index) {
    final taskToDelete = filteredTasks[index];

    // Find the actual index in the full task list (not just filtered)
    final actualIndex = tasks.indexOf(taskToDelete);

    if (actualIndex != -1) {
      taskBox?.deleteAt(actualIndex);
      tasks.removeAt(actualIndex);
      filteredTasks.removeAt(index);
      NotificationService.cancelNotification(actualIndex);
    }
  }

  void sortByPriority() {
    final sorted = List<TaskModel>.from(filteredTasks);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    filteredTasks.assignAll(sorted);
  }

  void sortByDueDate() {
    final sorted = List<TaskModel>.from(filteredTasks);
    sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    filteredTasks.assignAll(sorted);
  }

  void sortByCreatedAt() {
    final sorted = List<TaskModel>.from(filteredTasks);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    filteredTasks.assignAll(sorted);
  }

  void scheduleReminder(TaskModel task, int id) {
    if (task.dueDate.isAfter(DateTime.now())) {
      NotificationService.scheduleNotification(
        id: id,
        title: 'Task Reminder',
        body: '${task.title} is due soon!',
        scheduledDate: task.dueDate.subtract(const Duration(minutes: 1)),
      );
    }
  }

  void searchTasks(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredTasks.assignAll(tasks);
    } else {
      filteredTasks.assignAll(
        tasks.where(
          (task) =>
              task.title.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()),
        ),
      );
    }
  }

  void sortTasks(String option) {
    sortOption.value = option;
    List<TaskModel> sorted = List.from(filteredTasks);
    switch (option) {
      case 'Priority':
        sorted.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'Due Date':
        sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      default:
        sorted = List.from(tasks); // default: creation order
    }
    filteredTasks.assignAll(sorted);
  }
}
