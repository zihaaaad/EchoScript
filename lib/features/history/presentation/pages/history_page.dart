import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/audio_chunk.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isar = ref.watch(isarProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Intelligence Archive",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ),
      body: StreamBuilder<List<AudioChunk>>(
        stream: isar.audioChunks
            .where()
            .sortByStartTimeDesc()
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          
          final chunks = snapshot.data!;
          if (chunks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, size: 40, color: AppTheme.textSecondary.withValues(alpha: 0.1)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Archive is currently empty",
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: chunks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _BentoHistoryCard(chunk: chunks[index]),
          );
        },
      ),
    );
  }
}

class _BentoHistoryCard extends StatelessWidget {
  final AudioChunk chunk;
  const _BentoHistoryCard({required this.chunk});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(chunk.startTime);
    final dateStr = DateFormat('MMM dd, yyyy').format(chunk.startTime);
    final duration = chunk.endTime != null 
        ? chunk.endTime!.difference(chunk.startTime).inMinutes 
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        timeStr,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
                      ),
                    ),
                    _StatusBadge(status: chunk.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                Text(
                  "$duration minute intelligence session",
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                if (chunk.transcription != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      chunk.transcription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => _DetailView(chunk: chunk),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(anim1),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final AudioChunk chunk;
  const _DetailView({required this.chunk});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20, color: AppTheme.primary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              DateFormat('EEEE, MMM dd').format(chunk.startTime),
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(chunk.startTime),
              style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "TRANSCRIPTION",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    chunk.transcription ?? "Recording intelligence is still processing...",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.7,
                      color: chunk.transcription == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ChunkStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          status.name.toUpperCase(),
          style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ChunkStatus.completed: return AppTheme.success;
      case ChunkStatus.failed: return AppTheme.error;
      case ChunkStatus.transcribing: return Colors.blueAccent;
      default: return AppTheme.textSecondary;
    }
  }
}
