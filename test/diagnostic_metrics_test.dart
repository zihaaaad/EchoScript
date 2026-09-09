import 'package:flutter_test/flutter_test.dart';
import 'package:echoscript/core/utils/diagnostic_service.dart';

void main() {
  group('DiagnosticMetrics Tests', () {
    test('DiagnosticMetrics instantiates and calculates correctly', () {
      final metrics = DiagnosticMetrics(
        totalRecordings: 10,
        successRecordings: 9,
        failedRecordings: 1,
        pendingRecordings: 0,
        successRate: 90.0,
        avgDurationSeconds: 180.0,
        freeDiskSpaceMb: 2048.0,
        isApiKeyValid: true,
      );

      expect(metrics.totalRecordings, equals(10));
      expect(metrics.successRecordings, equals(9));
      expect(metrics.failedRecordings, equals(1));
      expect(metrics.pendingRecordings, equals(0));
      expect(metrics.successRate, equals(90.0));
      expect(metrics.avgDurationSeconds, equals(180.0));
      expect(metrics.freeDiskSpaceMb, equals(2048.0));
      expect(metrics.isApiKeyValid, isTrue);
    });
  });
}
