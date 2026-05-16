import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:echoscript/main.dart';
import 'package:echoscript/features/settings/domain/models/app_settings.dart';

class MockIsar extends Mock implements Isar {}
class MockIsarCollection extends Mock implements IsarCollection<AppSettings> {}
class MockQuery extends Mock implements Query<AppSettings> {}

void main() {
  late MockIsar mockIsar;
  late MockIsarCollection mockCollection;

  setUp(() {
    mockIsar = MockIsar();
    mockCollection = MockIsarCollection();
    
    when(() => mockIsar.appSettings).thenReturn(mockCollection);
    when(() => mockCollection.watchObject(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((_) => Stream.value(AppSettings()..isRecordingActive = false));
  });

  testWidgets('EchoScript Dashboard smoke test', (WidgetTester tester) async {
    // Set a reasonable surface size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(mockIsar),
        ],
        child: const EchoScriptApp(),
      ),
    );

    // pumpAndSettle to handle any animations or async UI updates
    await tester.pumpAndSettle();

    // Verify key elements exist by looking for the App Bar title
    expect(find.text('EchoScript'), findsWidgets);
    
    // Verify that the recording button (Mic icon) is present
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    
    // Clean up
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
