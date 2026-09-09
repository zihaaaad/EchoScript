import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/diagnostic_service.dart';
import '../../domain/models/app_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _promptController = TextEditingController();
  
  bool _obscureApiKey = true;
  bool _isSaving = false;
  bool _isInitialConfigLoaded = false;
  
  double _gainMultiplier = 1.0;
  int _chunkIntervalMinutes = AppConstants.defaultChunkIntervalMinutes;
  String _selectedModel = AppConstants.modelFlash;

  DiagnosticMetrics? _metrics;
  bool _isLoadingMetrics = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadMetrics();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _loadApiKey() {
    final apiKey = ref.read(apiKeyStateProvider);
    apiKey.whenData((val) {
      if (val != null && mounted) {
        _apiKeyController.text = val;
      }
    });
  }

  void _initLocalSettings(AppSettings settings) {
    if (!_isInitialConfigLoaded) {
      _isInitialConfigLoaded = true;
      _gainMultiplier = settings.gainMultiplier;
      _chunkIntervalMinutes = settings.chunkIntervalMinutes;
      _selectedModel = settings.selectedModel;
      if (_promptController.text.isEmpty) {
        _promptController.text = settings.systemPrompt;
      }
    }
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoadingMetrics = true);
    try {
      final diagService = ref.read(diagnosticServiceProvider);
      final data = await diagService.getMetrics();
      if (mounted) {
        setState(() {
          _metrics = data;
          _isLoadingMetrics = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMetrics = false);
      }
    }
  }

  String _getGainDbLabel(double multiplier) {
    if (multiplier == 1.0) return '1.0x (Original)';
    if (multiplier == 0.25) return '0.25x (-12 dB)';
    if (multiplier == 0.5) return '0.5x (-6 dB)';
    if (multiplier == 2.0) return '2.0x (+6 dB)';
    if (multiplier == 4.0) return '4.0x (+12 dB)';
    if (multiplier == 8.0) return '8.0x (+18 dB)';
    if (multiplier == 16.0) return '16.0x (+24 dB)';
    return '${multiplier.toStringAsFixed(1)}x';
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isSaving = true);
    
    // Save API key
    await ref.read(apiKeyStateProvider.notifier).setApiKey(_apiKeyController.text);

    // Save prompt and database settings
    final updated = AppSettings()
      ..id = 0
      ..gainMultiplier = _gainMultiplier
      ..chunkIntervalMinutes = _chunkIntervalMinutes
      ..selectedModel = _selectedModel
      ..systemPrompt = _promptController.text
      ..isFirstLaunch = false;

    await ref.read(settingsStateProvider.notifier).updateSettings(updated);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStateProvider);

    return Scaffold(
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (settings) {
            _initLocalSettings(settings);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),

                  // Section: API Key
                  _buildSectionHeader('Gemini API Integration'),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'API Access Key',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          decoration: InputDecoration(
                            hintText: 'Paste Gemini API Key here...',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Model Choice',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedModel,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          items: const [
                            DropdownMenuItem(
                              value: AppConstants.modelFlash,
                              child: Text('Gemini 1.5 Flash (Recommended, Fast)'),
                            ),
                            DropdownMenuItem(
                              value: AppConstants.modelPro,
                              child: Text('Gemini 1.5 Pro (High Accuracy)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedModel = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Audio Settings
                  _buildSectionHeader('Recording Configuration'),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Software Mic Gain',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              _getGainDbLabel(_gainMultiplier),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _gainMultiplier,
                          min: 0.25,
                          max: 16.0,
                          // Map to specific gain levels
                          divisions: 6,
                          onChanged: (val) {
                            setState(() {
                              // Force value alignment with common multipliers
                              final levels = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0];
                              double nearest = levels.first;
                              double minDiff = (val - nearest).abs();
                              for (final lvl in levels) {
                                final diff = (val - lvl).abs();
                                if (diff < minDiff) {
                                   minDiff = diff;
                                   nearest = lvl;
                                }
                              }
                              _gainMultiplier = nearest;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Recording Chunk Interval',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _chunkIntervalMinutes,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 Minute (Developer/Test)')),
                            DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                            DropdownMenuItem(value: 30, child: Text('30 Minutes (Default)')),
                            DropdownMenuItem(value: 60, child: Text('60 Minutes')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _chunkIntervalMinutes = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: System Prompt
                  _buildSectionHeader('AI Prompt Engineering'),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transcription Instruction',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _promptController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter AI transcription instructions...',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Diagnostics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Diagnostics'),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                        onPressed: _loadMetrics,
                        tooltip: 'Refresh Diagnostics',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDiagnosticsModule(),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAllSettings,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('SAVE ALL SETTINGS'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDiagnosticsModule() {
    if (_isLoadingMetrics) {
      return const GlassCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final m = _metrics;
    if (m == null) {
      return const GlassCard(
        child: Center(
          child: Text('Click refresh icon to load metrics', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    final keyStatusColor = m.isApiKeyValid ? Colors.greenAccent : Colors.redAccent;
    final successRateColor = m.successRate >= 90 ? Colors.greenAccent : Colors.orangeAccent;

    return GlassCard(
      child: Column(
        children: [
          _buildDiagRow(
            label: 'API Key Verification',
            value: m.isApiKeyValid ? 'Active / Valid' : 'Failed / Inactive',
            valueColor: keyStatusColor,
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.white10),
          _buildDiagRow(
            label: 'Transcripts in Vault',
            value: '${m.totalRecordings} chunk(s)',
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.white10),
          _buildDiagRow(
            label: 'Sync Success Rate',
            value: '${m.successRate.toStringAsFixed(1)}%',
            valueColor: successRateColor,
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.white10),
          _buildDiagRow(
            label: 'Failed Chunks (Retry Queue)',
            value: '${m.failedRecordings} chunk(s)',
            valueColor: m.failedRecordings > 0 ? Colors.orangeAccent : Colors.grey,
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.white10),
          _buildDiagRow(
            label: 'Average Audio Length',
            value: '${(m.avgDurationSeconds / 60).toStringAsFixed(1)} min',
          ),
          const Divider(height: 16, thickness: 0.5, color: Colors.white10),
          _buildDiagRow(
            label: 'Device Free Storage',
            value: m.freeDiskSpaceMb > 1024
                ? '${(m.freeDiskSpaceMb / 1024).toStringAsFixed(1)} GB'
                : '${m.freeDiskSpaceMb.toStringAsFixed(0)} MB',
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow({required String label, required String value, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
