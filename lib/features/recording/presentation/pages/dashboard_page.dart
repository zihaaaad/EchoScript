import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disk_space_2/disk_space_2.dart';

import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/permission_manager.dart';
import '../../data/repositories/recording_manager.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  double _freeDiskMb = 0.0;
  bool _micGranted = false;
  bool _notifyGranted = false;
  bool _batteryIgnored = false;

  @override
  void initState() {
    super.initState();
    _checkSystemHealth();
  }

  Future<void> _checkSystemHealth() async {
    final free = await DiskSpace.getFreeDiskSpace ?? 0.0;
    final mic = await PermissionManager.requestMicrophonePermission();
    final notify = await PermissionManager.requestNotificationPermission();
    final battery = await PermissionManager.isBatteryOptimizationIgnored();

    if (mounted) {
      setState(() {
        _freeDiskMb = free;
        _micGranted = mic;
        _notifyGranted = notify;
        _batteryIgnored = battery;
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleRecording(RecordingStateModel stateModel) async {
    final manager = ref.read(recordingManagerProvider.notifier);

    // Request permissions before starting
    if (!stateModel.isRecording) {
      final keyState = ref.read(apiKeyStateProvider);
      if (keyState.value == null || keyState.value!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add your Gemini API Key in Settings first!'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final permissionsOk = await PermissionManager.requestMandatoryPermissions();
      if (!permissionsOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone and Notification permissions are required to record.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      
      await manager.startRecording();
    } else {
      await manager.stopRecording();
    }
    _checkSystemHealth();
  }

  @override
  Widget build(BuildContext context) {
    final stateModel = ref.watch(recordingManagerProvider);
    final isRecording = stateModel.isRecording;
    final elapsedText = _formatDuration(stateModel.elapsedSeconds);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E C H O S C R I P T',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recorder',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  if (stateModel.queueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stateModel.queueCount} in queue',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),

              // Disk space alert banner
              if (stateModel.diskSpaceWarning != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stateModel.diskSpaceWarning!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Visualizer Panel / Record Timer
              SizedBox(
                width: double.infinity,
                child: GlassCard(
                  child: Column(
                    children: [
                      Text(
                        isRecording ? 'RECORDING SESSION' : 'SYSTEM IDLE',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: isRecording ? Colors.redAccent : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        elapsedText,
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRecording
                            ? 'Audio chunks rotating automatically'
                            : 'Tap mic below to initiate background capture',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Animated Record Button
              PulseRecordButton(
                isRecording: isRecording,
                onTap: () => _toggleRecording(stateModel),
              ),

              const SizedBox(height: 50),

              // System Health Module
              Text(
                'System Health',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HealthCard(
                      title: 'Storage',
                      subtitle: _freeDiskMb > 1024
                          ? '${(_freeDiskMb / 1024).toStringAsFixed(1)} GB Free'
                          : '${_freeDiskMb.toStringAsFixed(0)} MB Free',
                      icon: Icons.storage_rounded,
                      isOk: _freeDiskMb > 500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _HealthCard(
                      title: 'Microphone',
                      subtitle: _micGranted ? 'Authorized' : 'Action Required',
                      icon: Icons.mic_rounded,
                      isOk: _micGranted,
                      onTap: () async {
                        final ok = await PermissionManager.requestMicrophonePermission();
                        setState(() => _micGranted = ok);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HealthCard(
                      title: 'Notifications',
                      subtitle: _notifyGranted ? 'Enabled' : 'Action Required',
                      icon: Icons.notifications_active_rounded,
                      isOk: _notifyGranted,
                      onTap: () async {
                        final ok = await PermissionManager.requestNotificationPermission();
                        setState(() => _notifyGranted = ok);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _HealthCard(
                      title: 'Battery Saver',
                      subtitle: _batteryIgnored ? 'Optimized' : 'Saver Active',
                      icon: Icons.battery_charging_full_rounded,
                      isOk: _batteryIgnored,
                      onTap: () async {
                        final ok = await PermissionManager.requestIgnoreBatteryOptimizations();
                        setState(() => _batteryIgnored = ok);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isOk;
  final VoidCallback? onTap;

  const _HealthCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isOk,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOk ? Colors.greenAccent : Colors.orangeAccent;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderColor: statusColor.withOpacity(0.15),
        child: Row(
          children: [
            Icon(icon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isOk ? Colors.grey.shade400 : Colors.orangeAccent.shade100,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
