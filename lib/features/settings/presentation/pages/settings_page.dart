import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/app_settings.dart';
import '../../../../shared/widgets/modern_widgets.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _promptController = TextEditingController();
  double _gain = 0.0;
  String _model = 'gemini-1.5-flash';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loadSettings() async {
    final isar = ref.read(isarProvider);
    final settings = await isar.appSettings.get(0);
    if (settings != null) {
      setState(() {
        _apiKeyController.text = settings.geminiApiKey ?? '';
        _promptController.text = settings.systemPrompt;
        _gain = settings.audioGainDb;
        _model = settings.geminiModel;
      });
    }
  }

  Future<void> _saveSettings() async {
    final isar = ref.read(isarProvider);
    final settings = await isar.appSettings.get(0) ?? AppSettings();
    
    settings.geminiApiKey = _apiKeyController.text;
    settings.systemPrompt = _promptController.text;
    settings.audioGainDb = _gain;
    settings.geminiModel = _model;

    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Preferences synchronized", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuration"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ModernButton(
                label: "SAVE",
                onTap: _saveSettings,
                icon: Icons.done_all_rounded,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          _buildSectionHeader("AI ENGINE"),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: _inputDecoration("Gemini API Key", Icons.key_rounded),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _model,
                  dropdownColor: AppTheme.surface,
                  icon: const Icon(Icons.expand_more_rounded, color: AppTheme.primary),
                  style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _inputDecoration("Intelligence Model", Icons.auto_awesome_rounded),
                  items: const [
                    DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('1.5 Flash (Performance)')),
                    DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('1.5 Pro (Accuracy)')),
                  ],
                  onChanged: (val) => setState(() => _model = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader("AUDIO DSP"),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Microphone Gain", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_gain.toStringAsFixed(1)} dB",
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 5),
                  ),
                  child: Slider(
                    value: _gain,
                    min: -12.0,
                    max: 24.0,
                    divisions: 36,
                    onChanged: (val) => setState(() => _gain = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader("SYSTEM PROMPT"),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(28),
            child: TextField(
              controller: _promptController,
              maxLines: 6,
              style: GoogleFonts.inter(fontSize: 15, height: 1.6, fontWeight: FontWeight.w400),
              decoration: _inputDecoration("Logic Instructions", Icons.psychology_alt_rounded).copyWith(
                hintText: "Configure the AI behavior...",
              ),
            ),
          ),
          const SizedBox(height: 60),
          Column(
            children: [
              Text(
                "ECHOSCRIPT",
                style: GoogleFonts.manrope(
                  letterSpacing: 6,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Build $_appVersion",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w700),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      border: InputBorder.none,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }
}
