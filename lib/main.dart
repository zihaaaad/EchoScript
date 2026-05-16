// (c) 2026 Zihad Hasan | EchoScript Intelligence Unit
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/history/domain/models/audio_chunk.dart';
import 'features/settings/domain/models/app_settings.dart';
import 'core/constants/constants.dart';
import 'core/utils/background_service_utils.dart';
import 'features/recording/presentation/pages/dashboard_page.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [AudioChunkSchema, AppSettingsSchema],
    directory: dir.path,
    name: AppConstants.dbName,
  );

  await initializeBackgroundService();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        secureStorageProvider.overrideWithValue(const FlutterSecureStorage()),
      ],
      child: const EchoScriptApp(),
    ),
  );
}

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError();
});

class EchoScriptApp extends StatelessWidget {
  const EchoScriptApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const DashboardPage(),
    );
}
