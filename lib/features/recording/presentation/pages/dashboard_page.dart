import 'dart:ui';
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
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await PermissionManager.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Depth
          Positioned.fill(
            child: Container(
              color: AppTheme.background,
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildModernAppBar(context),
                const SizedBox(height: 60),
                const StatusMonitor(),
                const Spacer(),
                const WaveformVisualizer(),
                const Spacer(),
                const RecordingController(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ECHOSCRIPT",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Intelligence Unit",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _CircularAction(
                icon: Icons.history_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                ),
              ),
              const SizedBox(width: 16),
              _CircularAction(
                icon: Icons.tune_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.error : AppTheme.success).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isActive ? AppTheme.error : AppTheme.success).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BlinkingDot(color: isActive ? AppTheme.error : AppTheme.success),
                  const SizedBox(width: 12),
                  Text(
                    isActive ? "ACTIVE RECORDING" : "SYSTEM STANDBY",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isActive ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(
              isActive ? "00:42:15" : "00:00:00",
              style: GoogleFonts.manrope(
                fontSize: 80,
                fontWeight: FontWeight.w200,
                letterSpacing: -4,
                color: AppTheme.textPrimary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive ? "TRANSCRIBING IN BACKGROUND" : "READY FOR CAPTURE",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppTheme.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final Color color;
  const _BlinkingDot({required this.color});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
        ),
      ),
    );
  }
}

class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(30, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4,
            height: 10 + (index % 5 * 15).toDouble(),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}

class RecordingController extends ConsumerWidget {
  const RecordingController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AppSettings?>(
      stream: ref.watch(isarProvider).appSettings.watchObject(0, fireImmediately: true),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final isActive = settings?.isRecordingActive ?? false;
        
        return GestureDetector(
          onTap: () async {
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
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isActive ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.05),
                ),
              ),
              // Main Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.error : AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive 
                      ? [const Color(0xFFFF3B30), const Color(0xFFFF2D55)]
                      : [AppTheme.primary, const Color(0xFF007AFF)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    isActive ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
