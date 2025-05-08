import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  // Define our app theme colors
  final Color primaryColor = const Color(0xFF6B4AA0);
  final Color secondaryColor = const Color(0xFF5C3D97);
  final Color backgroundColor = const Color(0xFFF5F5F7);

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

  String formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('MMM d, yyyy - h:mm a');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.isEdit ? 'Edit Task' : 'Add Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              buildTextField(
                controller: titleController,
                label: 'Task Title',
                icon: Icons.title,
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),
              buildTextField(
                controller: descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              buildPrioritySelector(),
              const SizedBox(height: 20),
              buildDateTimeSelector(),
              const SizedBox(height: 40),
              buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelText: label,
          labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  Widget buildPrioritySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<int>(
        value: selectedPriority,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          labelText: 'Priority',
          labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
          prefixIcon: Icon(Icons.flag, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          DropdownMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.red, size: 14),
                const SizedBox(width: 8),
                const Text('High'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 2,
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.orange, size: 14),
                const SizedBox(width: 8),
                const Text('Medium'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 3,
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 14),
                const SizedBox(width: 8),
                const Text('Low'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          setState(() => selectedPriority = value!);
        },
        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget buildDateTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.calendar_month, color: primaryColor),
        title: Text(
          selectedDate == null
              ? 'Select Due Date & Time'
              : 'Due: ${formatDateTime(selectedDate!)}',
          style: TextStyle(
            color: selectedDate == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
        onTap: _pickDateTime,
      ),
    );
  }

  Widget buildSubmitButton() {
    return ElevatedButton(
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
          Get.snackbar(
            'Missing Date',
            'Please select a due date and time',
            backgroundColor: Colors.red.shade50,
            colorText: Colors.red.shade700,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Text(
        widget.isEdit ? 'Update Task' : 'Add Task',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
}