import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/user_data.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  factory NotificationService() => instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes timezone data, notification settings, and notification channels.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error initializing timezone: $e');
      // Fallback to UTC location if local lookup fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Android Initialization Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS / macOS Initialization Settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    // 4. Request Android 13+ permission
    await requestPermissions();

    _isInitialized = true;
  }

  /// Requests notification permissions for Android 13+ and iOS/macOS.
  Future<bool> requestPermissions() async {
    bool granted = false;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? result = await androidImplementation.requestNotificationsPermission();
      granted = result ?? false;
    }

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final bool? result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }

    return granted;
  }

  /// Syncs review notifications for the given user data.
  /// Automatically schedules a notification at 12:00 AM on each day with pending reviews.
  Future<void> syncReviewNotifications(UserData? userData) async {
    if (!_isInitialized) {
      await init();
    }

    if (userData == null || userData.subjects.isEmpty) {
      await _notificationsPlugin.cancelAll();
      return;
    }

    final now = DateTime.now();
    final todayStr = _formatDateIso(now);

    // Collect review tasks per date
    // Key: ISO Date string (YYYY-MM-DD), Value: List of review subjects/notes
    final Map<String, List<String>> pendingReviewsByDate = {};
    final Map<String, List<String>> completedReviewsByDate = {};

    for (final subject in userData.subjects) {
      for (final note in subject.notes) {
        for (final reminder in note.reminders) {
          final rDate = DateTime.tryParse(reminder);
          if (rDate == null) continue;

          final dateStr = _formatDateIso(rDate);

          final isDone = note.completedReminders.any((cr) {
            final crDate = DateTime.tryParse(cr);
            return crDate != null &&
                crDate.year == rDate.year &&
                crDate.month == rDate.month &&
                crDate.day == rDate.day;
          });

          if (isDone) {
            completedReviewsByDate.putIfAbsent(dateStr, () => []).add(subject.name);
          } else {
            pendingReviewsByDate.putIfAbsent(dateStr, () => []).add('${subject.name}: ${note.content}');
          }
        }
      }
    }

    // Process all dates found
    final allDates = {...pendingReviewsByDate.keys, ...completedReviewsByDate.keys};

    for (final dateStr in allDates) {
      final dateObj = DateTime.tryParse(dateStr);
      if (dateObj == null) continue;

      final notificationId = _generateNotificationId(dateStr);
      final pendingList = pendingReviewsByDate[dateStr] ?? [];

      // If all reviews on this date are completed or there are no pending tasks
      if (pendingList.isEmpty) {
        await _notificationsPlugin.cancel(notificationId);
        continue;
      }

      // Target time: 12:00 AM (00:00:00) on the review date
      final targetTzDateTime = tz.TZDateTime(
        tz.local,
        dateObj.year,
        dateObj.month,
        dateObj.day,
        0, // 12:00 AM Hour
        0, // Minute
        0, // Second
      );

      final subjectCount = pendingList.length;
      final bodyText = subjectCount == 1
          ? 'You have 1 study review scheduled today. Tap to open Study Smart!'
          : 'You have $subjectCount study reviews scheduled today. Tap to start reviewing!';

      // If review date is today
      if (dateStr == todayStr) {
        // If 12:00 AM has already passed today, show immediate notification if not completed
        final nowTz = tz.TZDateTime.now(tz.local);
        if (targetTzDateTime.isBefore(nowTz)) {
          await _showImmediateNotification(
            id: notificationId,
            title: '📚 Study Smart Review Reminder',
            body: bodyText,
            payload: dateStr,
          );
        } else {
          await _scheduleNotification(
            id: notificationId,
            scheduledDate: targetTzDateTime,
            title: '📚 Study Smart Review Reminder',
            body: bodyText,
            payload: dateStr,
          );
        }
      } else if (targetTzDateTime.isAfter(tz.TZDateTime.now(tz.local))) {
        // Future review date @ 12:00 AM
        await _scheduleNotification(
          id: notificationId,
          scheduledDate: targetTzDateTime,
          title: '📚 Study Smart Review Reminder',
          body: bodyText,
          payload: dateStr,
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_smart_reviews',
            'Study Review Reminders',
            channelDescription: 'Automatic 12:00 AM alerts for scheduled study reviews.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling 12:00 AM notification (id: $id): $e');
    }
  }

  Future<void> _showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_smart_reviews',
            'Study Review Reminders',
            channelDescription: 'Automatic 12:00 AM alerts for scheduled study reviews.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing immediate review notification: $e');
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Helper to convert YYYY-MM-DD into a deterministic integer notification ID.
  int _generateNotificationId(String dateStr) {
    return dateStr.replaceAll('-', '').hashCode & 0x7FFFFFFF;
  }

  String _formatDateIso(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
