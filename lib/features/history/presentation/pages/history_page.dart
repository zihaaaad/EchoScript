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
      appBar: AppBar(
        title: const Text("Vault"),
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
                  Icon(Icons.folder_open_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
                  const SizedBox(height: 24),
                  Text(
                    "Archive is currently empty",
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            itemCount: chunks.length,
            itemBuilder: (context, index) {
              final chunk = chunks[index];
              return _ModernHistoryCard(chunk: chunk);
            },
          );
        },
      ),
    );
  }
}

class _ModernHistoryCard extends StatelessWidget {
  final AudioChunk chunk;
  const _ModernHistoryCard({required this.chunk});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(chunk.startTime);
    final dateStr = DateFormat('MMM dd, yyyy').format(chunk.startTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _showDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  _buildStatusIndicator(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeStr,
                              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          chunk.transcription ?? "Decoding audio streams...",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: chunk.transcription == null ? AppTheme.textSecondary.withValues(alpha: 0.5) : AppTheme.textPrimary.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Icon(
        _getStatusIcon(),
        color: color,
        size: 22,
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('EEEE, MMM dd').format(chunk.startTime).toUpperCase(),
                        style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat('HH:mm').format(chunk.startTime),
                  style: GoogleFonts.manrope(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                Text(
                  "TRANSCRIPTION",
                  style: GoogleFonts.inter(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
                Text(
                  chunk.transcription ?? "The AI is currently processing your recording. High-fidelity results will appear here shortly.",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    height: 1.7,
                    fontWeight: FontWeight.w400,
                    color: chunk.transcription == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 60),
                Center(
                  child: ModernButton(
                    label: "COPY TO CLIPBOARD",
                    onTap: () {},
                    icon: Icons.copy_all_rounded,
                    isPrimary: false,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        chunk.status.name.toUpperCase(),
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
      ),
    );
  }

  Color _getStatusColor() {
    switch (chunk.status) {
      case ChunkStatus.completed: return AppTheme.success;
      case ChunkStatus.failed: return AppTheme.error;
      case ChunkStatus.transcribing: return Colors.amber;
      default: return AppTheme.primary;
    }
  }

  IconData _getStatusIcon() {
    switch (chunk.status) {
      case ChunkStatus.completed: return Icons.check_circle_rounded;
      case ChunkStatus.failed: return Icons.warning_rounded;
      case ChunkStatus.transcribing: return Icons.auto_mode_rounded;
      default: return Icons.radio_button_checked_rounded;
    }
  }
}
