import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  PermissionManager._();

  /// Requests microphone recording permission.
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Requests POST_NOTIFICATIONS permission for Android 13+.
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Checks if battery optimization is currently ignored.
  static Future<bool> isBatteryOptimizationIgnored() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Requests the OS prompt to disable battery optimization for the app.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Checks if the mandatory permissions (microphone + notifications) are granted.
  static Future<bool> hasMandatoryPermissions() async {
    final micGranted = await Permission.microphone.isGranted;
    final notificationGranted = await Permission.notification.isGranted;
    return micGranted && notificationGranted;
  }

  /// Requests both mandatory permissions sequentially.
  static Future<bool> requestMandatoryPermissions() async {
    final mic = await requestMicrophonePermission();
    if (!mic) return false;
    
    final notify = await requestNotificationPermission();
    return notify;
  }
}
