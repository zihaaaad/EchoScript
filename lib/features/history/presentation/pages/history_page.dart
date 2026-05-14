import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/audio_chunk.dart';
import '../../../../shared/widgets/modern_widgets.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isar = ref.watch(isarProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Archive"),
        centerTitle: false,
      ),
      body: StreamBuilder<List<AudioChunk>>(
        stream: isar.audioChunks
            .where()
            .sortByStartTimeDesc()
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final chunks = snapshot.data!;
          if (chunks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    "No recordings found",
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: chunks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _CleanHistoryCard(chunk: chunks[index]);
            },
          );
        },
      ),
    );
  }
}

class _CleanHistoryCard extends StatelessWidget {
  final AudioChunk chunk;
  const _CleanHistoryCard({required this.chunk});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(chunk.startTime);
    final dateStr = DateFormat('MMM dd, yyyy').format(chunk.startTime);
    
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  _StatusChip(status: chunk.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (chunk.transcription != null) ...[
                const SizedBox(height: 12),
                Text(
                  chunk.transcription!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                DateFormat('EEEE, MMMM dd').format(chunk.startTime),
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(chunk.startTime),
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.white10),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TRANSCRIPTION",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        chunk.transcription ?? "Processing transcription...",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.6,
                          color: chunk.transcription == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ModernButton(
                  label: "Copy Transcript",
                  onTap: () {},
                  icon: Icons.copy_rounded,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ChunkStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.5),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ChunkStatus.completed: return AppTheme.success;
      case ChunkStatus.failed: return AppTheme.error;
      case ChunkStatus.transcribing: return Colors.orangeAccent;
      default: return AppTheme.primary;
    }
  }
}
