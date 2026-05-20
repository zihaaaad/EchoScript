import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../features/history/domain/models/audio_chunk.dart';

class ExportService {
  ExportService._();

  /// Shares the transcription as a UTF-8 formatted .txt file
  static Future<void> shareAsTxt(AudioChunk chunk) async {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(chunk.createdAt);
    final text = """
EchoScript Transcription Record
==================================================
Date: $dateStr
Duration: ${chunk.durationSeconds} seconds
Words: ${chunk.wordCount}
==================================================

${chunk.transcript ?? ''}
""";

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/transcript_${chunk.id}.txt');
    await file.writeAsString(text);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'EchoScript Transcript - ${DateFormat('yyyy-MM-dd').format(chunk.createdAt)}',
    );
  }

  /// Shares the transcription as a high-quality formatted PDF document
  static Future<void> shareAsPdf(AudioChunk chunk) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(chunk.createdAt);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'EchoScript Transcription Report',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                pw.Text(
                  dateStr,
                  style: const pw.TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Duration: ${chunk.durationSeconds} seconds',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Word Count: ${chunk.wordCount} words',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 12),
          pw.Paragraph(
            text: chunk.transcript ?? 'No transcription text available.',
            style: const pw.TextStyle(
              fontSize: 12,
              lineSpacing: 2,
            ),
          ),
        ],
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/transcript_${chunk.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'EchoScript Transcript - ${DateFormat('yyyy-MM-dd').format(chunk.createdAt)}',
    );
  }
}
