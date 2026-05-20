import 'package:isar/isar.dart';

part 'audio_chunk.g.dart';

@collection
class AudioChunk {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String filePath;

  @Index()
  late String status; // 'PENDING', 'PROCESSING', 'DONE', 'FAILED'

  String? transcript;

  @Index()
  late DateTime createdAt;

  late int durationSeconds;

  late int wordCount;

  late int retryCount;
}
