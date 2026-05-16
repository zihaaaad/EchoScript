import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/export_service.dart';
import '../../domain/models/audio_chunk.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transcript Vault',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search transcripts...',
                hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _buildTranscriptList(),
          ),
        ],
      ),
    );

  Widget _buildTranscriptList() {
    final isar = ref.watch(isarProvider);
    
    final query = _searchQuery.isEmpty 
      ? isar.audioChunks.where().sortByStartTimeDesc()
      : isar.audioChunks.filter()
          .transcriptionWordsElementStartsWith(_searchQuery, caseSensitive: false)
          .sortByStartTimeDesc();

    return StreamBuilder<List<AudioChunk>>(
      stream: query.watch(fireImmediately: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final chunks = snapshot.data ?? [];
        if (chunks.isEmpty) {
          return Center(
            child: Text(
              'No transcripts found.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: chunks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _TranscriptCard(chunk: chunks[index]),
        );
      },
    );
  }
}

class _TranscriptCard extends ConsumerWidget {
  final AudioChunk chunk;
  
  const _TranscriptCard({required this.chunk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = chunk.endTime != null 
        ? chunk.endTime!.difference(chunk.startTime)
        : DateTime.now().difference(chunk.startTime);
        
    final isCompleted = chunk.status == ChunkStatus.completed;

    return InkWell(
      onTap: () {
        if (isCompleted && chunk.transcription != null) {
          _showTranscriptDetails(context, chunk);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(chunk.startTime),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                _buildStatusBadge(chunk.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted 
                ? (chunk.transcription ?? 'Empty transcription').trim() 
                : _getStatusMessage(chunk.status),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${duration.inMinutes}m ${duration.inSeconds % 60}s',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 18, color: AppTheme.textSecondary),
                        onPressed: () => ExportService.shareAsTxt(chunk),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                        onPressed: () async {
                          final isar = ref.read(isarProvider);
                          await isar.writeTxn(() async {
                            await isar.audioChunks.delete(chunk.id);
                          });
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(ChunkStatus status) {
    switch (status) {
      case ChunkStatus.recording: return 'Currently recording...';
      case ChunkStatus.pending: return 'Waiting in queue...';
      case ChunkStatus.transcribing: return 'AI is transcribing...';
      case ChunkStatus.failed: return 'Transcription failed (retrying)';
      case ChunkStatus.completed: return '';
    }
  }

  Widget _buildStatusBadge(ChunkStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case ChunkStatus.recording:
        color = AppTheme.error;
        label = 'RECORDING';
        break;
      case ChunkStatus.pending:
        color = Colors.orange;
        label = 'PENDING';
        break;
      case ChunkStatus.transcribing:
        color = AppTheme.primary;
        label = 'PROCESSING';
        break;
      case ChunkStatus.completed:
        color = AppTheme.success;
        label = 'READY';
        break;
      case ChunkStatus.failed:
        color = AppTheme.error;
        label = 'ERROR';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _showTranscriptDetails(BuildContext context, AudioChunk chunk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, HH:mm').format(chunk.startTime),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: chunk.transcription ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.textSecondary),
                        onPressed: () => ExportService.shareAsPdf(chunk),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: Text(
                  chunk.transcription ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
