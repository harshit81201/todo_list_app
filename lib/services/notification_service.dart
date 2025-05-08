import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async'; // For Timer

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  // Add this flag to track initialization status
  static bool _isInitialized = false;

  // Add troubleshooting flags
  static bool _useAlternativeScheduling = true;
  static bool _enableExtraLogging = true;

  static Future<void> init({bool forceReinit = false}) async {
    if (_isInitialized && !forceReinit) {
      print('[INIT] NotificationService already initialized.');
      return;
    }
    
    print('[INIT] Initializing timezones...');
    tz.initializeTimeZones();

    try {
      // Set timezone directly without using flutter_native_timezone
      try {
        // Using a default timezone instead of detecting - change this to match your target region
        // You might want to hardcode the timezone that most of your users are in
        tz.setLocalLocation(tz.getLocation('America/New_York'));
        print('[INIT] Time zone set to America/New_York (default)');
      } catch (e) {
        print('[INIT] Error setting timezone: $e');
        // Fallback to UTC
        tz.setLocalLocation(tz.UTC);
        print('[INIT] Fallback to UTC timezone');
      }

      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        
      );

      final InitializationSettings settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      print('[INIT] Initializing notifications plugin...');
      bool initSuccess = await _notificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (details) {
          print('[NOTIF] Notification tapped: ${details.payload}');
          developer.log('Notification tapped: ${details.payload}');
        },
      ) ?? false;
      
      print('[INIT] Initialization success: $initSuccess');

      print('[INIT] Creating Android notification channel...');
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'todo_channel',
        'Task Reminders',
        description: 'Task due notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'), // Try with a custom sound
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('[INIT] Notification channel created');
        
        if (Platform.isAndroid) {
          // Request notification permissions
          print('[INIT] Requesting notification permission...');
          final bool? hasPermission = await androidPlugin.areNotificationsEnabled();
          print('[INIT] Current notification permission: $hasPermission');
          
          if (hasPermission != true) {
            final bool? permissionResult = await androidPlugin.requestNotificationsPermission();
            print('[INIT] Permission request result: $permissionResult');
          }
          
          // Check and request exact alarms permission - THIS IS CRITICAL FOR SCHEDULED NOTIFICATIONS
          try {
            final bool? canScheduleExactAlarms =
                await androidPlugin.canScheduleExactNotifications();
            print('[INIT] Can schedule exact alarms: $canScheduleExactAlarms');
            
            if (canScheduleExactAlarms == false) {
              print('[INIT] Requesting exact alarm permission...');
              final bool? requestResult = await androidPlugin.requestExactAlarmsPermission();
              print('[INIT] Exact alarm permission request result: $requestResult');
              
              // Verify permission was granted
              final bool? permissionGranted = 
                  await androidPlugin.canScheduleExactNotifications();
              print('[INIT] Exact alarm permission granted: $permissionGranted');
              
              if (permissionGranted == false) {
                print('[WARN] ⚠️ EXACT ALARM PERMISSION DENIED! This is required for scheduled notifications.');
                print('[WARN] Please guide the user to enable this in system settings.');
              }
            }
          } catch (e) {
            print('[ERROR] Error checking exact alarm permissions: $e');
          }
        }
      } else {
        print('[INIT] Platform implementation is null');
      }

      _isInitialized = true;
      print('[INIT] NotificationService initialized successfully.');
      
      // Test notifications are working
      Timer(const Duration(seconds: 5), () {
        showInstantNotification();
      });
    } catch (e) {
      print('[ERROR][INIT] $e');
      developer.log('Error setting up notifications: $e');
    }
  }

  static Future<void> sendTestNotification() async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) await init();
      
      await cancelNotification(9999); // Cancel any existing test notification
      
      final DateTime now = DateTime.now();
      final DateTime scheduledDate = now.add(const Duration(seconds: 10));

      print('[SEND TEST] Now: $now');
      
      // Convert to TZ datetime properly
      final tz.TZDateTime scheduledTzDate = _convertToTZDateTime(scheduledDate);
      
      print('[SEND TEST] Scheduled time: $scheduledTzDate');

      // First, show an immediate notification to verify basic functionality
      await showInstantNotification();
      
      // Then schedule the actual test notification
      await _notificationsPlugin.zonedSchedule(
        9999,
        'Test Notification',
        'This is a test notification scheduled for: ${scheduledDate.toString()}',
        scheduledTzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel',
            'Task Reminders',
            channelDescription: 'Task due notifications',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            ticker: 'Test notification ticker',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('[SEND TEST] Test notification scheduled successfully.');

      // Show all pending notifications for debugging
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      print('[DEBUG] Pending notifications: ${pending.length}');
      for (var p in pending) {
        print('[PENDING] ID=${p.id}, Title=${p.title}, Body=${p.body}');
      }
    } catch (e) {
      print('[ERROR][SEND TEST] $e');
      developer.log('Error scheduling test notification: $e');
    }
  }

  static Future<void> showInstantNotification() async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) await init();
      
      print('[INSTANT] Showing instant notification...');
      await _notificationsPlugin.show(
        8888,
        'Instant Test Notification',
        'This notification should appear immediately: ${DateTime.now()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel',
            'Task Reminders',
            channelDescription: 'Task due notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('[INSTANT] Instant notification shown.');
    } catch (e) {
      print('[ERROR][INSTANT] $e');
      developer.log('Error showing instant notification: $e');
    }
  }

  // Improved helper method to properly convert DateTime to tz.TZDateTime
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Make sure we're working with a non-UTC DateTime - explicitly set to local
    final localDateTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
    
    // Convert to TZ format using the previously configured local timezone
    final tz.TZDateTime result = tz.TZDateTime.from(localDateTime, tz.local);
    
    if (_enableExtraLogging) {
      print('[TZ] Input DateTime: $dateTime');
      print('[TZ] Local DateTime: $localDateTime');
      print('[TZ] Converted TZDateTime: $result');
      print('[TZ] Current TZ local: ${tz.local.name}');
      print('[TZ] TZ offset: ${result.timeZoneOffset}');
    }
    
    return result;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) await init();
      
      // Cancel any existing notification with this ID first
      await cancelNotification(id);
      
      print('[SCHEDULE] Scheduling notification: $id @ $scheduledDate');

      // Use our helper method to correctly convert the DateTime
      final tz.TZDateTime scheduledTzDate = _convertToTZDateTime(scheduledDate);
      print('[SCHEDULE] TZ scheduled time: $scheduledTzDate');
      
      // Check if the time is in the future
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      if (scheduledTzDate.isBefore(now)) {
        print('[WARN] Scheduled time is in the past! Adjusting to 30 seconds from now.');
        // Adjust to near future instead of skipping
        final adjustedTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));
        print('[WARN] Adjusted time: $adjustedTime');
        
        // Continue with adjusted time
        await _scheduleNotificationWithTime(id, title, body, adjustedTime, payload);
        return;
      }
      
      await _scheduleNotificationWithTime(id, title, body, scheduledTzDate, payload);
      
      // If using alternative scheduling, also try a fallback approach
      if (_useAlternativeScheduling) {
        await _scheduleBackupNotification(id, title, body, scheduledDate);
      }
    } catch (e) {
      print('[ERROR][SCHEDULE] $e');
      developer.log('Error scheduling notification: $e');
      
      // Attempt emergency fallback if normal scheduling fails
      _emergencyFallbackScheduling(id, title, body, scheduledDate);
    }
  }
  
  // Main scheduling function
  static Future<void> _scheduleNotificationWithTime(
    int id, 
    String title, 
    String body, 
    tz.TZDateTime scheduledTime,
    String? payload
  ) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel',
            'Task Reminders',
            channelDescription: 'Task due notifications',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true, 
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      print('[SCHEDULE] Notification $id scheduled successfully for $scheduledTime');
      
      // Verify by checking pending notifications
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      final scheduledNotif = pending.where((n) => n.id == id).toList();
      if (scheduledNotif.isNotEmpty) {
        print('[VERIFY] Notification $id found in pending list.');
      } else {
        print('[WARN] Notification $id NOT found in pending list!');
      }
    } catch (e) {
      print('[ERROR] Failed to schedule notification: $e');
      throw e;  // Re-throw so calling code can handle it
    }
  }
  
  // Alternative scheduling method as backup
  static Future<void> _scheduleBackupNotification(
    int id, 
    String title, 
    String body, 
    DateTime scheduledDate
  ) async {
    try {
      // Use a different ID for the backup
      final backupId = id + 10000;
      
      // Calculate time difference
      final now = DateTime.now();
      final difference = scheduledDate.difference(now);
      
      if (difference.inSeconds > 0) {
        print('[BACKUP] Setting up backup notification with ID $backupId using Timer');
        
        // Create a delayed task
        Timer(difference, () {
          print('[BACKUP] Timer fired for notification $backupId');
          _notificationsPlugin.show(
            backupId,
            title,
            '$body (Backup notification)',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'todo_channel',
                'Task Reminders',
                channelDescription: 'Task due notifications',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        });
        
        print('[BACKUP] Backup notification timer set for $difference from now');
      } else {
        print('[BACKUP] Scheduled time is in the past, skipping backup');
      }
    } catch (e) {
      print('[ERROR][BACKUP] $e');
    }
  }
  
  // Last resort emergency scheduling
  static void _emergencyFallbackScheduling(
    int id, 
    String title, 
    String body, 
    DateTime scheduledDate
  ) {
    try {
      print('[EMERGENCY] Attempting emergency fallback scheduling');
      
      // Calculate seconds until scheduled time
      final now = DateTime.now();
      final secondsUntil = scheduledDate.difference(now).inSeconds;
      
      if (secondsUntil > 0) {
        // Use a different ID to avoid conflicts
        final emergencyId = id + 20000;
        
        print('[EMERGENCY] Setting timer for $secondsUntil seconds from now');
        
        // Just use a basic timer as absolute last resort
        Timer(Duration(seconds: secondsUntil), () {
          print('[EMERGENCY] Timer triggered, showing notification $emergencyId');
          
          _notificationsPlugin.show(
            emergencyId,
            title,
            '$body (Emergency fallback)',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'todo_channel',
                'Task Reminders', 
                channelDescription: 'Task due notifications',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        });
        
        print('[EMERGENCY] Emergency timer scheduled');
      } else {
        print('[EMERGENCY] Time already passed, skipping emergency scheduling');
      }
    } catch (e) {
      print('[ERROR][EMERGENCY] $e');
    }
  }

  static bool shouldScheduleNotification(DateTime dueDate) {
    final result = dueDate.isAfter(DateTime.now());
    print('[CHECK] Should schedule? $result for dueDate: $dueDate');
    return result;
  }

  static Future<void> cancelNotification(int id) async {
    try {
      print('[CANCEL] Cancelling notification $id...');
      await _notificationsPlugin.cancel(id);
      
      // Also cancel any backup notifications
      await _notificationsPlugin.cancel(id + 10000);
      await _notificationsPlugin.cancel(id + 20000);
      
      print('[CANCEL] Notification $id cancelled (including backups).');
    } catch (e) {
      print('[ERROR][CANCEL] $e');
      developer.log('Error cancelling notification: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      print('[CANCEL] Cancelling all notifications...');
      await _notificationsPlugin.cancelAll();
      print('[CANCEL] All notifications cancelled.');
    } catch (e) {
      print('[ERROR][CANCEL] $e');
      developer.log('Error cancelling all notifications: $e');
    }
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final list = await _notificationsPlugin.pendingNotificationRequests();
    print('[DEBUG] Fetched ${list.length} pending notifications.');
    for (var p in list) {
      print('[PENDING] ID=${p.id}, Title=${p.title}, Body=${p.body}');
    }
    return list;
  }

  
  
  // Add this method to check notification settings on the device
  static Future<void> checkNotificationSettings() async {
    try {
      print('[CHECK] Checking notification settings...');
      
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          try {
            final bool? areNotificationsEnabled = 
                await androidPlugin.areNotificationsEnabled();
            print('[CHECK] Notifications enabled: $areNotificationsEnabled');
            
            final bool? canScheduleExact = 
                await androidPlugin.canScheduleExactNotifications();
            print('[CHECK] Can schedule exact alarms: $canScheduleExact');
            
            if (canScheduleExact != true) {
              print('[WARN] ⚠️ EXACT ALARM PERMISSION IS MISSING! This is required for scheduled notifications.');
              print('[WARN] Please request exact alarm permission or guide user to enable it in settings.');
            }
          } catch (e) {
            print('[ERROR] Error checking notification settings: $e');
          }
        }
      } else if (Platform.isIOS) {
        // On iOS we can't directly check permissions, but we can log what we've requested
        print('[CHECK] iOS notifications were initialized with permission requests.');
      }
    } catch (e) {
      print('[ERROR][CHECK] $e');
    }
  }
}