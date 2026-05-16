import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/diagnostic_service.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class SystemHealthModule extends ConsumerWidget {
  const SystemHealthModule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(systemHealthProvider);

    return healthAsync.when(
      data: (health) => _buildModule(context, health),
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, _) => _buildErrorState(err),
    );
  }

  Widget _buildModule(BuildContext context, SystemHealth health) {
    final statusColor = _getColor(health.overallStatus);
    final statusIcon = _getIcon(health.overallStatus);

    return InkWell(
      onTap: () => _showDiagnostics(context, health),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusLabel(health.overallStatus),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'System Health',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 24),
        const SizedBox(height: 4),
        Text(
          'Diagnostic Error',
          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );

  Color _getColor(DiagnosticStatus status) => switch (status) {
        DiagnosticStatus.healthy => AppTheme.success,
        DiagnosticStatus.warning => Colors.orange,
        DiagnosticStatus.critical => AppTheme.error,
      };

  IconData _getIcon(DiagnosticStatus status) => switch (status) {
        DiagnosticStatus.healthy => Icons.check_circle_outline_rounded,
        DiagnosticStatus.warning => Icons.warning_amber_rounded,
        DiagnosticStatus.critical => Icons.gpp_maybe_rounded,
      };

  String _getStatusLabel(DiagnosticStatus status) => switch (status) {
        DiagnosticStatus.healthy => 'READY',
        DiagnosticStatus.warning => 'ATTENTION',
        DiagnosticStatus.critical => 'ISSUE',
      };

  void _showDiagnostics(BuildContext context, SystemHealth health) => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => _DiagnosticsBottomSheet(health: health),
      );
}

class _DiagnosticsBottomSheet extends StatelessWidget {
  final SystemHealth health;
  const _DiagnosticsBottomSheet({required this.health});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Engine Diagnostics',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Icon(Icons.analytics_outlined, color: AppTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Verifying 24/7 background recording integrity...',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...health.pillars.map((p) => _buildPillarRow(context, p)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPillarRow(BuildContext context, PillarStatus p) {
    final color = _getPillarColor(p.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getPillarIcon(p.status), color: color, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    p.message,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (p.status != DiagnosticStatus.healthy)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (p.name == 'AI Engine') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  }
                  // Add more navigation logic for other fixes if needed
                },
                style: TextButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  p.actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPillarColor(DiagnosticStatus status) => switch (status) {
        DiagnosticStatus.healthy => AppTheme.success,
        DiagnosticStatus.warning => Colors.orange,
        DiagnosticStatus.critical => AppTheme.error,
      };

  IconData _getPillarIcon(DiagnosticStatus status) => switch (status) {
        DiagnosticStatus.healthy => Icons.check,
        DiagnosticStatus.warning => Icons.priority_high_rounded,
        DiagnosticStatus.critical => Icons.close_rounded,
      };
}
