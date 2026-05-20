import 'package:disk_space_2/disk_space_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../features/recording/domain/repositories/transcription_repositories.dart';
import '../../core/constants/constants.dart';

class DiagnosticMetrics {
  final int totalRecordings;
  final int successRecordings;
  final int failedRecordings;
  final int pendingRecordings;
  final double successRate;
  final double avgDurationSeconds;
  final double freeDiskSpaceMb;
  final bool isApiKeyValid;

  DiagnosticMetrics({
    required this.totalRecordings,
    required this.successRecordings,
    required this.failedRecordings,
    required this.pendingRecordings,
    required this.successRate,
    required this.avgDurationSeconds,
    required this.freeDiskSpaceMb,
    required this.isApiKeyValid,
  });
}

class DiagnosticService {
  final TranscriptionRepository _repository;
  final FlutterSecureStorage _secureStorage;

  DiagnosticService(this._repository, this._secureStorage);

  Future<DiagnosticMetrics> getMetrics() async {
    final chunks = await _repository.getAllChunks();
    final total = chunks.length;
    final done = chunks.where((c) => c.status == 'DONE').length;
    final failed = chunks.where((c) => c.status == 'FAILED').length;
    final pending = chunks
        .where((c) => c.status == 'PENDING' || c.status == 'PROCESSING')
        .length;

    final rate = total > 0 ? (done / total) * 100 : 100.0;

    double avgDuration = 0.0;
    if (total > 0) {
      final sum = chunks.fold(0, (prev, element) => prev + element.durationSeconds);
      avgDuration = sum / total;
    }

    double freeDisk = 0.0;
    try {
      final disk = await DiskSpace.getFreeDiskSpace;
      if (disk != null) {
        freeDisk = disk;
      }
    } catch (_) {}

    // Verify API Key with a lightweight request
    bool isKeyValid = false;
    final apiKey = await _secureStorage.read(key: AppConstants.secureApiKeyName);
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
        final response = await http.get(url).timeout(const Duration(seconds: 4));
        isKeyValid = response.statusCode == 200;
      } catch (_) {
        isKeyValid = false;
      }
    }

    return DiagnosticMetrics(
      totalRecordings: total,
      successRecordings: done,
      failedRecordings: failed,
      pendingRecordings: pending,
      successRate: rate,
      avgDurationSeconds: avgDuration,
      freeDiskSpaceMb: freeDisk,
      isApiKeyValid: isKeyValid,
    );
  }
}
