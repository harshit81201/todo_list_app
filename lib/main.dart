import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task_model.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register adapter
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());

  // Open the Hive box for tasks
  await Hive.openBox<TaskModel>('tasks');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ToDoList App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
