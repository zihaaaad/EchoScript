import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../../core/utils/permission_manager.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final granted = await PermissionManager.requestPermissions();
    if (mounted) {
      setState(() => _isPermissionGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            const Spacer(),
            const StatusMonitor(),
            if (!_isPermissionGranted) ...[
              const SizedBox(height: 24),
              _buildPermissionWarning(),
            ],
            const Spacer(),
            const WaveformVisualizer(),
            const SizedBox(height: 60),
            RecordingController(isEnabled: _isPermissionGranted),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Permissions required to start recording",
              style: GoogleFonts.inter(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: _initPermissions,
            child: const Text("GRANT", style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "EchoScript",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  "Enterprise Audio Intelligence",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _ActionIcon(
            icon: Icons.history_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            ),
          ),
          const SizedBox(width: 12),
          _ActionIcon(
            icon: Icons.settings_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }
}

class StatusMonitor extends ConsumerWidget {
  const StatusMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AppSettings?>(
      stream: ref.watch(isarProvider).appSettings.watchObject(0, fireImmediately: true),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final isActive = settings?.isRecordingActive ?? false;
        
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.error : AppTheme.success).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (isActive ? AppTheme.error : AppTheme.success).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.error : AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? "RECORDING" : "STANDBY",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isActive ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isActive ? "00:42:15" : "00:00:00",
              style: GoogleFonts.inter(
                fontSize: 72,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive ? "System actively capturing audio" : "Tap to start intelligence session",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(40, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 2.5,
            height: 4 + (index % 7 * 4).toDouble(),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class RecordingController extends ConsumerWidget {
  final bool isEnabled;
  const RecordingController({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AppSettings?>(
      stream: ref.watch(isarProvider).appSettings.watchObject(0, fireImmediately: true),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final isActive = settings?.isRecordingActive ?? false;
        
        return Opacity(
          opacity: isEnabled ? 1.0 : 0.3,
          child: Material(
            color: isActive ? AppTheme.error : AppTheme.primary,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              onTap: isEnabled ? () async {
                final isar = ref.read(isarProvider);
                final currentSettings = await isar.appSettings.get(0) ?? AppSettings();
                
                await isar.writeTxn(() async {
                  currentSettings.isRecordingActive = !isActive;
                  await isar.appSettings.put(currentSettings);
                });

                final service = FlutterBackgroundService();
                if (!isActive) {
                  await service.startService();
                  service.invoke("startRecording");
                } else {
                  service.invoke("stopRecording");
                }
              } : null,
              customBorder: const CircleBorder(),
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(
                  isActive ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
