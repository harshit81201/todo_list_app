import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../models/task_model.dart';

class TaskFormView extends StatefulWidget {
  final bool isEdit;
  final TaskModel? task;
  final int? index;

  const TaskFormView({
    super.key,
    this.isEdit = false,
    this.task,
    this.index,
  });

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final TaskController controller = Get.find<TaskController>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  int selectedPriority = 2;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.task != null) {
      titleController.text = widget.task!.title;
      descriptionController.text = widget.task!.description;
      selectedDate = widget.task!.dueDate;
      selectedPriority = widget.task!.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Task' : 'Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() => selectedPriority = value!);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  selectedDate == null
                      ? 'Select Due Date & Time'
                      : 'Due: ${selectedDate.toString()}',
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && selectedDate != null) {
                    final newTask = TaskModel(
                      title: titleController.text,
                      description: descriptionController.text,
                      priority: selectedPriority,
                      dueDate: selectedDate!,
                      createdAt: DateTime.now(),
                    );

                    if (widget.isEdit && widget.index != null) {
                      controller.updateTask(widget.index!, newTask);
                    } else {
                      controller.addTask(newTask);
                    }

                    Get.back(); // Navigate back to HomeView
                  } else if (selectedDate == null) {
                    Get.snackbar('Error', 'Please select a due date');
                  }
                },
                child: Text(widget.isEdit ? 'Update Task' : 'Add Task'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedDate = DateTime(
          date!.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
    }
}
