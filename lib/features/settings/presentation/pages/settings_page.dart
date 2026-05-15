import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/app_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _promptController = TextEditingController();
  double _gain = 0.0;
  int _concurrency = 2;
  int _chunkDuration = 30;
  String _model = 'gemini-2.5-flash';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  Future<void> _loadSettings() async {
    final isar = ref.read(isarProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final settings = await isar.appSettings.get(0);
    final apiKey = await secureStorage.read(key: 'gemini_api_key');
    
    if (settings != null) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _promptController.text = settings.systemPrompt;
        _gain = settings.audioGainDb;
        _model = settings.geminiModel;
        _concurrency = settings.aiConcurrencyLimit;
        _chunkDuration = settings.chunkDurationMinutes;
      });
    }
  }

  Future<void> _saveSettings() async {
    final isar = ref.read(isarProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final settings = await isar.appSettings.get(0) ?? AppSettings();
    
    await secureStorage.write(key: 'gemini_api_key', value: _apiKeyController.text);
    settings.systemPrompt = _promptController.text;
    settings.audioGainDb = _gain;
    settings.geminiModel = _model;
    settings.aiConcurrencyLimit = _concurrency;
    settings.chunkDurationMinutes = _chunkDuration;

    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cloud synchronicity confirmed"),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Control Center",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              "SYNC",
              style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildBentoSection(
            "Intelligence Engine",
            Column(
              children: [
                _buildTextField("Gemini API Key", _apiKeyController, isPassword: true),
                const SizedBox(height: 24),
                _buildDropdown("Processor Model", _model, (val) => setState(() => _model = val!)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBentoSection(
            "Hardware DSP",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Software Gain", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text("${_gain.toStringAsFixed(1)} dB", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _gain,
                  min: -12.0,
                  max: 24.0,
                  divisions: 36,
                  onChanged: (val) => setState(() => _gain = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBentoSection(
            "Hardware Optimization",
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("AI Concurrency", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text("$_concurrency Units", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _concurrency.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (val) => setState(() => _concurrency = val.toInt()),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Chunk Rotation", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    Text("$_chunkDuration Min", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _chunkDuration.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  onChanged: (val) => setState(() => _chunkDuration = val.toInt()),
                ),
                Text(
                  "Defines the duration of audio segments. Higher units increase throughput but require more device RAM and stable network.",
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBentoSection(
            "System Protocols",
            _buildTextField("Core Instructions", _promptController, maxLines: 4),
          ),
          const SizedBox(height: 60),
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Text(
                "ECHOSCRIPT ENTERPRISE v$_appVersion",
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 1),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: Container(height: 1, color: Colors.white12),
          dropdownColor: AppTheme.surface,
          items: const [
            DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('2.5 Flash (Recommended)')),
            DropdownMenuItem(value: 'gemini-2.5-pro', child: Text('2.5 Pro (Deep Reasoning)')),
            DropdownMenuItem(value: 'gemini-3.1-flash-lite', child: Text('3.1 Flash-Lite (Fastest)')),
            DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('1.5 Flash (Legacy)')),
            DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('1.5 Pro (Legacy)')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
