import 'dart:async';
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
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final granted = await PermissionManager.requestPermissions();
    if (mounted) setState(() => _isPermissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background ambient glow
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildBentoGrid(),
                          const SizedBox(height: 20),
                          _buildRecentActivity(),
                          const SizedBox(height: 100), // Space for controller
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: RecordingController(isEnabled: _isPermissionGranted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EchoScript",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              Text(
                "v1.0.0+11 • Enterprise",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _CircularButton(
                icon: Icons.history_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
              ),
              const SizedBox(width: 12),
              _CircularButton(
                icon: Icons.settings_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        const BentoModule(
          title: "Session Time",
          child: StatusMonitor(),
        ),
        BentoModule(
          title: "Storage",
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage_rounded, color: AppTheme.accent, size: 28),
              const SizedBox(height: 8),
              Text(
                "2.4 GB",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                "Available",
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Activity Monitor",
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const Icon(Icons.auto_graph_rounded, color: AppTheme.success, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final heights = [20.0, 45.0, 30.0, 60.0, 25.0, 50.0, 40.0];
              return Container(
                width: 30,
                height: heights[index],
                decoration: BoxDecoration(
                  color: index == 3 ? AppTheme.primary : AppTheme.card,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) {
              return SizedBox(
                width: 30,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class BentoModule extends StatelessWidget {
  final String title;
  final Widget child;
  const BentoModule({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1),
          ),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }
}

class StatusMonitor extends ConsumerStatefulWidget {
  const StatusMonitor({super.key});

  @override
  ConsumerState<StatusMonitor> createState() => _StatusMonitorState();
}

class _StatusMonitorState extends ConsumerState<StatusMonitor> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer(DateTime? startTime) {
    _timer?.cancel();
    if (startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _elapsed = DateTime.now().difference(startTime));
      });
      _elapsed = DateTime.now().difference(startTime);
    } else {
      _elapsed = Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSettings?>(
      stream: ref.watch(isarProvider).appSettings.watchObject(0, fireImmediately: true),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final isActive = settings?.isRecordingActive ?? false;
        final startTime = settings?.recordingStartTime;

        if (isActive && startTime != null) {
          if (_timer == null || !_timer!.isActive) _updateTimer(startTime);
        } else {
          _timer?.cancel();
          _timer = null;
          _elapsed = Duration.zero;
        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${_elapsed.inHours}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isActive ? AppTheme.error : AppTheme.textPrimary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.error : AppTheme.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isActive) BoxShadow(color: AppTheme.error.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? "LIVE" : "IDLE",
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? AppTheme.error : AppTheme.success),
                ),
              ],
            ),
          ],
        );
      },
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
        
        return GestureDetector(
          onTap: isEnabled ? () async {
            final isar = ref.read(isarProvider);
            final currentSettings = await isar.appSettings.get(0) ?? AppSettings();
            await isar.writeTxn(() async {
              currentSettings.isRecordingActive = !isActive;
              currentSettings.recordingStartTime = !isActive ? DateTime.now() : null;
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
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive 
                    ? [AppTheme.error, const Color(0xFF9F1239)] 
                    : [AppTheme.primary, const Color(0xFF1E40AF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(
                isActive ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        );
      },
    );
  }
}
