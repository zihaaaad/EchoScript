import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:echoscript/main.dart';
import 'package:echoscript/features/history/domain/models/audio_chunk.dart';
import 'package:echoscript/features/settings/domain/models/app_settings.dart';

void main() {
  testWidgets('EchoScript Dashboard smoke test', (WidgetTester tester) async {
    // Set a larger surface size to avoid RenderFlex overflow in tests
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    // Note: We don't initialize Isar here because the main dashboard 
    // uses it via StreamBuilders, and we can override providers if needed.
    // For a basic smoke test, we just want to see if the UI builds.
    
    await tester.pumpWidget(
      const ProviderScope(
        child: EchoScriptApp(),
      ),
    );

    // Verify that our app title or key elements are present.
    expect(find.text('ECHOSCRIPT'), findsOneWidget);
    expect(find.text('Intelligence Unit'), findsOneWidget);
    
    // Verify recording controller exists
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    // Clean up
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
