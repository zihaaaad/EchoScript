import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PermissionManager {
  static final Logger _logger = Logger();

  static Future<bool> requestPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.notification,
    ].request();

    final bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (!allGranted) {
      _logger.w('Some permissions were denied.');
    }
    
    // Request to ignore battery optimization
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    return allGranted;
  }
}
