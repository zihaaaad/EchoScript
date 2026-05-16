import 'package:disk_space_2/disk_space_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/recording/data/datasources/transcription_service.dart';
import '../../features/settings/domain/models/app_settings.dart';

enum DiagnosticStatus { healthy, warning, critical }

class PillarStatus {
  final String name;
  final DiagnosticStatus status;
  final String message;
  final String actionLabel;

  PillarStatus({
    required this.name,
    required this.status,
    required this.message,
    this.actionLabel = 'Fix',
  });
}

class SystemHealth {
  final List<PillarStatus> pillars;
  final DiagnosticStatus overallStatus;

  SystemHealth({required this.pillars, required this.overallStatus});
}

class DiagnosticService {
  final TranscriptionService transcriptionService;
  final FlutterSecureStorage secureStorage;
  final Isar isar;

  DiagnosticService({
    required this.transcriptionService,
    required this.secureStorage,
    required this.isar,
  });

  Future<SystemHealth> runFullDiagnostics() async {
    final pillars = await Future.wait([
      _checkApiHealth(),
      _checkStorageHealth(),
      _checkBatteryHealth(),
      _checkMicrophoneHealth(),
    ]);

    final overall = pillars.any((p) => p.status == DiagnosticStatus.critical)
        ? DiagnosticStatus.critical
        : pillars.any((p) => p.status == DiagnosticStatus.warning)
            ? DiagnosticStatus.warning
            : DiagnosticStatus.healthy;

    return SystemHealth(pillars: pillars, overallStatus: overall);
  }

  Future<PillarStatus> _checkApiHealth() async {
    final key = await secureStorage.read(key: 'gemini_api_key');
    if (key == null || key.isEmpty) {
      return PillarStatus(
        name: 'AI Engine',
        status: DiagnosticStatus.critical,
        message: 'Gemini API Key is missing.',
        actionLabel: 'Add Key',
      );
    }

    if (!key.startsWith('AIza')) {
      return PillarStatus(
        name: 'AI Engine',
        status: DiagnosticStatus.critical,
        message: 'Invalid API Key format.',
        actionLabel: 'Fix Key',
      );
    }

    final settings = await isar.appSettings.get(0) ?? AppSettings();
    final isOnline = await transcriptionService.testApiKey(key, settings.geminiModel);
    
    if (!isOnline) {
      return PillarStatus(
        name: 'AI Engine',
        status: DiagnosticStatus.warning,
        message: 'API Connection failed or quota exceeded.',
        actionLabel: 'Test',
      );
    }

    return PillarStatus(
      name: 'AI Engine',
      status: DiagnosticStatus.healthy,
      message: 'Gemini AI is ready.',
      actionLabel: 'OK',
    );
  }

  Future<PillarStatus> _checkStorageHealth() async {
    final freeSpaceMb = await DiskSpace.getFreeDiskSpace ?? 0.0;
    
    if (freeSpaceMb < 500) {
      return PillarStatus(
        name: 'Storage',
        status: DiagnosticStatus.critical,
        message: 'Critical! Less than 500MB available.',
        actionLabel: 'Clear',
      );
    }

    if (freeSpaceMb < 1024) {
      return PillarStatus(
        name: 'Storage',
        status: DiagnosticStatus.warning,
        message: 'Low storage (under 1GB).',
        actionLabel: 'Clear',
      );
    }

    return PillarStatus(
      name: 'Storage',
      status: DiagnosticStatus.healthy,
      message: 'Ample storage available.',
      actionLabel: 'OK',
    );
  }

  Future<PillarStatus> _checkBatteryHealth() async {
    final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    
    if (!isIgnored) {
      return PillarStatus(
        name: 'OS Resilience',
        status: DiagnosticStatus.warning,
        message: 'Battery optimization may kill background tasks.',
        actionLabel: 'Bypass',
      );
    }

    return PillarStatus(
      name: 'OS Resilience',
      status: DiagnosticStatus.healthy,
      message: 'Background execution optimized.',
      actionLabel: 'OK',
    );
  }

  Future<PillarStatus> _checkMicrophoneHealth() async {
    final status = await Permission.microphone.status;
    
    if (status.isDenied || status.isPermanentlyDenied) {
      return PillarStatus(
        name: 'Microphone',
        status: DiagnosticStatus.critical,
        message: 'Microphone access is denied.',
        actionLabel: 'Enable',
      );
    }

    return PillarStatus(
      name: 'Microphone',
      status: DiagnosticStatus.healthy,
      message: 'Hardware access confirmed.',
      actionLabel: 'OK',
    );
  }
}
