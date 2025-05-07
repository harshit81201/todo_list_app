import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import 'dart:developer' as developer;

class TaskController extends GetxController {
  var tasks = <TaskModel>[].obs;
  Box<TaskModel>? taskBox;
  var filteredTasks = <TaskModel>[].obs;
  var searchQuery = ''.obs;
  var sortOption = 'Creation Date'.obs;

  // Define consistent notification time offset
  static const notificationOffset = Duration(minutes: 10);

  // Flag to track if we need to run Hive adapter migration
  final bool _needsMigration = false;

  @override
  void onInit() async {
    super.onInit();
    taskBox = Hive.box<TaskModel>("taskbox");

    // Check if migration is needed (when adding isCompleted field)
    if (_needsMigration) {
      await _migrateTaskModels();
    }

    // Initialize notification service first
    await NotificationService.init(forceReinit: true);
    
    // Verify notification permissions
    await NotificationService.checkNotificationSettings();

    // Then load tasks and schedule notifications
    loadTasks();
    filteredTasks.assignAll(tasks);

    // Debug: Check pending notifications
    await checkPendingNotifications();
  }

  // Migration helper for adding isCompleted field to existing tasks
  Future<void> _migrateTaskModels() async {
    developer.log('Starting task model migration...');
    try {
      final List<TaskModel> allTasks = taskBox?.values.toList() ?? [];

      for (int i = 0; i < allTasks.length; i++) {
        // Only if the field doesn't exist or is null
        taskBox?.putAt(i, allTasks[i].copyWith(isCompleted: false));
      }

      developer.log(
        'Migration completed successfully for ${allTasks.length} tasks',
      );
    } catch (e) {
      developer.log('Error during migration: $e');
    }
  }

  // Helper method to log pending notifications
  Future<void> checkPendingNotifications() async {
    final pending = await NotificationService.getPendingNotifications();
    developer.log('Pending notifications: ${pending.length}');
    for (var notification in pending) {
      developer.log('ID: ${notification.id}, Title: ${notification.title}');
    }
  }

  void loadTasks() {
    tasks.value = taskBox?.values.toList() ?? [];
    filteredTasks.assignAll(tasks);

    // Cancel all existing notifications first to avoid duplicates
    NotificationService.cancelAllNotifications().then((_) {
      // Re-schedule notifications for all loaded tasks
      for (int i = 0; i < tasks.length; i++) {
        scheduleReminder(tasks[i], i);
      }
    });
  }

  void addTask(TaskModel task) {
    tasks.add(task);
    final index = taskBox?.add(task) ?? -1;
    scheduleReminder(task, tasks.length - 1);
    filteredTasks.assignAll(tasks);

    developer.log('Task added: ${task.title}, ID: ${tasks.length - 1}');
  }

  void updateTask(int index, TaskModel updatedTask) {
    if (index < 0 || index >= tasks.length) return; // Safeguard

    // Store original task for comparison
    final oldTask = tasks[index];

    // Update in memory and storage
    tasks[index] = updatedTask;
    taskBox?.putAt(index, updatedTask);

    // Always update notification when task is updated
    NotificationService.cancelNotification(index);
    scheduleReminder(updatedTask, index);
    developer.log('Notification rescheduled for task ${updatedTask.title}');

    // Reflect changes in filteredTasks as well
    searchTasks(searchQuery.value); // This re-filters based on current search

    developer.log('Task updated: ${updatedTask.title}, ID: $index');
  }

  void deleteTask(int index) {
    // Get the actual task instance from the filtered list
    final taskToDelete = filteredTasks[index];

    // Find the actual index in the full task list
    final actualIndex = tasks.indexOf(taskToDelete);

    if (actualIndex != -1) {
      developer.log('Deleting task: ${taskToDelete.title}, ID: $actualIndex');

      // Cancel notification first
      NotificationService.cancelNotification(actualIndex);

      // Then delete from storage and memory
      taskBox?.deleteAt(actualIndex);
      tasks.removeAt(actualIndex);

      // Update filtered list
      filteredTasks.remove(taskToDelete);

      // Reschedule all notifications with updated indices
      rescheduleAllNotifications();
    }
  }

  // New method to reschedule all notifications with correct IDs
  void rescheduleAllNotifications() {
    NotificationService.cancelAllNotifications().then((_) {
      for (int i = 0; i < tasks.length; i++) {
        scheduleReminder(tasks[i], i);
      }
      developer.log('All notifications rescheduled after task deletion');
    });
  }

  void markTaskCompleted(int index, bool isCompleted) {
    if (index < 0 || index >= tasks.length) return;

    final updatedTask = tasks[index].copyWith(isCompleted: isCompleted);
    tasks[index] = updatedTask;
    taskBox?.putAt(index, updatedTask);

    // Cancel notification if task is completed
    if (isCompleted) {
      NotificationService.cancelNotification(index);
      developer.log(
        'Notification cancelled for completed task: ${updatedTask.title}',
      );
    } else {
      // Reschedule if marked as incomplete and due date is in future
      scheduleReminder(updatedTask, index);
    }

    // Update filtered list
    searchTasks(searchQuery.value);
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
    // Skip if task is already completed
    if (task.isCompleted) {
      developer.log('Skipped notification for completed task: ${task.title}');
      return;
    }

    final now = DateTime.now();
    
    // Calculate notification time (10 minutes before due)
    final notificationTime = task.dueDate.subtract(notificationOffset);
    
    // Only schedule if the due date is in the future
    if (task.dueDate.isAfter(now)) {
      if (notificationTime.isAfter(now)) {
        // Notification time is in the future, schedule it
        final minutesLeft = notificationTime.difference(now).inMinutes;

        NotificationService.scheduleNotification(
          id: id,
          title: 'Task Reminder: ${task.title}',
          body:
              task.description.isNotEmpty
                  ? '${task.description} (Due in 10 minutes)'
                  : 'This task is due in 10 minutes!',
          scheduledDate: notificationTime,
          payload: id.toString(),
        );

        developer.log(
          'Scheduled notification for "${task.title}" at $notificationTime '
          '(${minutesLeft} minutes from now)',
        );
      } else if (task.dueDate.isAfter(now)) {
        // Notification time is in the past but due date is still in the future
        // Schedule an immediate notification
        developer.log(
          'Notification time for "${task.title}" is in the past but task is still due. '
          'Scheduling immediate notification.',
        );
        
        NotificationService.scheduleNotification(
          id: id,
          title: 'Task Reminder: ${task.title}',
          body: 'This task is due soon!',
          scheduledDate: now.add(const Duration(seconds: 5)), // Schedule for 5 seconds from now
          payload: id.toString(),
        );
      } else {
        developer.log(
          'Skipped notification for "${task.title}" - both notification time and due date are in the past',
        );
      }
    } else {
      developer.log(
        'Skipped notification for "${task.title}" - due date is in the past',
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

    // Apply current sort after filtering
    applyCurrentSort();
  }

  // New helper method to maintain sorting after operations
  void applyCurrentSort() {
    sortTasks(sortOption.value);
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
      case 'Creation Date':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      default:
        sorted = List.from(tasks); // default: creation order
    }
    filteredTasks.assignAll(sorted);
  }

  // Method to check if notifications are working
  Future<void> testNotification() async {
    await NotificationService.sendTestNotification();
    developer.log('Test notification sent');
  }

  // Method to check notification settings
  Future<void> checkNotificationSettings() async {
    await NotificationService.checkNotificationSettings();
  }

  @override
  void onClose() {
    // Clean up resources if needed
    super.onClose();
  }
}