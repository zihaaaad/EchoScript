import 'package:isar/isar.dart';

part 'audio_chunk.g.dart';

@collection
class AudioChunk {
  // Model for audio chunks
  Id id = Isar.autoIncrement;

  late String filePath;
  late DateTime startTime;
  DateTime? endTime;
  
  @Enumerated(EnumType.name)
  late ChunkStatus status;
  
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get transcriptionWords => transcription?.split(RegExp(r'\s+')) ?? [];

  @Index(type: IndexType.value)
  String? transcription;
  String? errorMessage;
  int retryCount = 0;
  DateTime? lastAttemptTime;
}

enum ChunkStatus {
  recording,
  pending,
  transcribing,
  completed,
  failed,
}
