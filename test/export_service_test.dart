import 'package:flutter_test/flutter_test.dart';
import 'package:echoscript/core/utils/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('sanitizeForPdf replaces problematic unicode characters with safe Latin-1 glyphs', () {
      const input = '“EchoScript” — smart notes… • Bullet 1 · Bullet 2 ‘Quote’ – Dash';
      final sanitized = ExportService.sanitizeForPdf(input);

      expect(sanitized.contains('“'), isFalse);
      expect(sanitized.contains('”'), isFalse);
      expect(sanitized.contains('—'), isFalse);
      expect(sanitized.contains('…'), isFalse);
      expect(sanitized.contains('•'), isFalse);
      expect(sanitized.contains('‘'), isFalse);
      expect(sanitized.contains('’'), isFalse);
      expect(sanitized.contains('–'), isFalse);

      expect(sanitized, equals('"EchoScript" -- smart notes... * Bullet 1 - Bullet 2 \'Quote\' - Dash'));
    });

    test('sanitizeForPdf normalizes Windows and legacy line breaks', () {
      const input = 'Line 1\r\nLine 2\rLine 3\nLine 4';
      final sanitized = ExportService.sanitizeForPdf(input);

      expect(sanitized, equals('Line 1\nLine 2\nLine 3\nLine 4'));
    });
  });
}
