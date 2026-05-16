import 'package:google_generative_ai/google_generative_ai.dart';

abstract class AiEngine {
  Future<String?> generateContent(Iterable<Content> content);
}

class GeminiEngine implements AiEngine {
  final GenerativeModel model;
  GeminiEngine(this.model);

  @override
  Future<String?> generateContent(Iterable<Content> content) async {
    final response = await model.generateContent(content);
    return response.text;
  }
}
