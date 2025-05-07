import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../models/task_model.dart';
import 'task_form_view.dart';
import 'package:intl/intl.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final TaskController controller = Get.find<TaskController>();
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDoList App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(controller);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                controller.tasks.value = controller.searchTasks(value);
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.tasks.length,
                itemBuilder: (context, index) {
                  final TaskModel task = controller.tasks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Text(
                        'Due: ${DateFormat('dd MMM yyyy – hh:mm a').format(task.dueDate)}\nPriority: ${_getPriorityText(task.priority)}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          controller.deleteTask(index);
                        },
                      ),
                      onTap: () {
                        Get.to(() => TaskFormView(
                              isEdit: true,
                              task: task,
                              index: index,
                            ));
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const TaskFormView());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return "High";
      case 2:
        return "Medium";
      case 3:
        return "Low";
      default:
        return "Unknown";
    }
  }

  void _showSortOptions(TaskController controller) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('Sort by Priority'),
              onTap: () {
                controller.sortByPriority();
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Sort by Due Date'),
              onTap: () {
                controller.sortByDueDate();
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Sort by Created Date'),
              onTap: () {
                controller.sortByCreatedAt();
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
