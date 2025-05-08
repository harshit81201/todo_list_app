# Todo List App

A Flutter application for managing your daily tasks with notifications and local storage.

## Features

- Create, read, update, and delete tasks
- Set task priorities
- Schedule tasks with due dates and times
- Receive notifications for upcoming tasks
- Persistent local storage using Hive
- Clean and intuitive user interface

## Architecture

This project follows a clean architecture pattern with:

- **Models**: Data structures representing tasks
- **Controllers**: Business logic for task management
- **Views**: UI components
- **Services**: Notification handling and other services
- **Bindings**: Dependency injection

```
lib/
├── bindings/
│   └── task_binding.dart
├── controllers/
│   └── task_controller.dart
├── models/
│   ├── task_model.dart
│   └── task_model.g.dart
├── services/
│   └── notification_service.dart
├── views/
│   ├── home_view.dart
│   └── task_form_view.dart
└── main.dart
```


## Dependencies

- **flutter**: SDK for building cross-platform applications
- **get**: State management and navigation
- **hive** & **hive_flutter**: Local NoSQL database
- **flutter_local_notifications**: Local notification management
- **timezone** & **flutter_native_timezone**: Timezone handling for notifications
- **intl**: Internationalization and date formatting
- **path_provider**: Access to file system paths

## Development Dependencies

- **hive_generator**: Code generation for Hive models
- **build_runner**: Automated code generation
- **flutter_lints**: Recommended lint rules

## Getting Started

### Prerequisites

- Flutter SDK (^3.7.0)
- Dart SDK
- Android Studio / VS Code / IntelliJ IDEA

### Installation

1. Clone the repository:
[git clone https://github.com//todo_list_app.git](https://github.com/harshit81201/todo_list_app.git)

2. Navigate to the project directory:
cd todo_list_app

3. Install dependencies:
flutter pub get

4. Generate Hive models:
flutter pub run build_runner build --delete-conflicting-outputs

5. Run the app:
flutter run

## Usage

1. Launch the app
2. Add new tasks using the "+" button
3. Set task details including title, description, priority, and due date
4. Mark tasks as complete by tapping the checkbox
5. Edit or delete tasks using the provided options
6. Receive notifications for upcoming tasks

## License

This project is licensed under the MIT License. Feel free to use the code for educational purposes or as a reference.
