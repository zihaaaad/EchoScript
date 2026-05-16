import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../../core/providers/providers.dart';
import '../../../history/domain/models/audio_chunk.dart';

class AnalyticsDashboard extends ConsumerWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isar = ref.watch(isarProvider);
    final repo = ref.watch(audioChunkRepositoryProvider);

    return StreamBuilder<void>(
      stream: isar.audioChunks.watchLazy(fireImmediately: true),
      builder: (context, _) => FutureBuilder<List<AudioChunk>>(
          future: repo.getCompletedChunksToday(),
          builder: (context, snapshot) {
            final completedToday = snapshot.data?.length ?? 0;
            
            // Storage saved calculation (Average 30min PCM is ~57MB, whereas text is ~10KB)
            // For visual analytics, we'll show approximate space reclaimed by purge
            final estimatedMbSaved = completedToday * 57; 

            return Row(
              children: [
                Expanded(
                  child: _AnalyticsCard(
                    label: 'Transcribed',
                    value: completedToday.toString(),
                    unit: 'Chunks',
                    icon: Icons.auto_awesome_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnalyticsCard(
                    label: 'Space Saved',
                    value: estimatedMbSaved > 1024 
                        ? (estimatedMbSaved / 1024).toStringAsFixed(1) 
                        : estimatedMbSaved.toString(),
                    unit: estimatedMbSaved > 1024 ? 'GB' : 'MB',
                    icon: Icons.shutter_speed_rounded,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
}
