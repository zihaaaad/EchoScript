import 'package:flutter_test/flutter_test.dart';
import 'package:echoscript/core/constants/constants.dart';
import 'package:echoscript/features/settings/domain/models/app_settings.dart';

void main() {
  group('AppSettings Domain Model Tests', () {
    test('AppSettings initializes with proper values and can be modified', () {
      final settings = AppSettings()
        ..id = 0
        ..gainMultiplier = 1.0
        ..chunkIntervalMinutes = AppConstants.defaultChunkIntervalMinutes
        ..systemPrompt = AppConstants.defaultSystemPrompt
        ..selectedModel = AppConstants.modelFlash
        ..isFirstLaunch = true;

      expect(settings.id, equals(0));
      expect(settings.gainMultiplier, equals(1.0));
      expect(settings.chunkIntervalMinutes, equals(30));
      expect(settings.selectedModel, equals('gemini-1.5-flash'));
      expect(settings.isFirstLaunch, isTrue);
      expect(settings.systemPrompt, contains('verbatim'));

      settings.gainMultiplier = 2.0;
      settings.selectedModel = AppConstants.modelPro;
      settings.isFirstLaunch = false;

      expect(settings.gainMultiplier, equals(2.0));
      expect(settings.selectedModel, equals('gemini-1.5-pro'));
      expect(settings.isFirstLaunch, isFalse);
    });

    test('AppConstants contains expected model identifiers and limits', () {
      expect(AppConstants.modelFlash, equals('gemini-1.5-flash'));
      expect(AppConstants.modelPro, equals('gemini-1.5-pro'));
      expect(AppConstants.minRequiredDiskSpace, equals(500 * 1024 * 1024));
      expect(AppConstants.maxRetryCount, equals(5));
      expect(AppConstants.defaultChunkIntervalMinutes, equals(30));
    });
  });
}
