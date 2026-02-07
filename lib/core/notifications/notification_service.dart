import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification service stub for local push notifications
/// 
/// Note: Push notifications require flutter_local_notifications which
/// doesn't support Windows desktop. This stub provides the interface
/// so the app compiles on all platforms. On mobile, you can add the
/// full implementation.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _isInitialized = false;
  
  /// Check if notifications are supported on this platform
  /// Currently disabled - add flutter_local_notifications for mobile
  bool get isSupported => false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    // Stub - no initialization needed
    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    // Stub - always return false on unsupported platforms
    return false;
  }

  /// Schedule a task reminder notification
  Future<void> scheduleTaskReminder({
    required int id,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    // Stub - no-op on unsupported platforms
  }

  /// Schedule hydration reminder (repeating)
  Future<void> scheduleHydrationReminder({
    required int intervalHours,
  }) async {
    // Stub - no-op on unsupported platforms
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Stub - no-op on unsupported platforms
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    // Stub - no-op
  }

  /// Cancel all hydration reminders
  Future<void> cancelHydrationReminders() async {
    // Stub - no-op
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    // Stub - no-op
  }
}

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
