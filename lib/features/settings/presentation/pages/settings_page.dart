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
    final secureStorage = ref.read(secureStorageProvider);
    
    final settings = await isar.appSettings.get(0);
    final apiKey = await secureStorage.read(key: 'gemini_api_key');
    
    if (settings != null) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _promptController.text = settings.systemPrompt;
        _gain = settings.audioGainDb;
        _model = settings.geminiModel;
      });
    }
  }

  Future<void> _saveSettings() async {
    final isar = ref.read(isarProvider);
    final secureStorage = ref.read(secureStorageProvider);
    
    final settings = await isar.appSettings.get(0) ?? AppSettings();
    
    // 1. Save sensitive data to Secure Storage
    await secureStorage.write(key: 'gemini_api_key', value: _apiKeyController.text);

    // 2. Save non-sensitive data to Isar
    settings.systemPrompt = _promptController.text;
    settings.audioGainDb = _gain;
    settings.geminiModel = _model;

    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enterprise preferences synchronized"),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ModernButton(
                label: "Apply",
                onTap: _saveSettings,
                icon: Icons.lock_outline_rounded,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("SECURE AI CONFIGURATION"),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: _inputDecoration("Gemini API Key", Icons.vpn_key_outlined),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _model,
                  dropdownColor: AppTheme.surface,
                  decoration: _inputDecoration("Engine Model", Icons.bolt_outlined),
                  items: const [
                    DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('1.5 Flash')),
                    DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('1.5 Pro')),
                  ],
                  onChanged: (val) => setState(() => _model = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("HARDWARE DSP"),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Digital Gain", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    Text("${_gain.toStringAsFixed(1)} dB", style: GoogleFonts.inter(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
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
          const SizedBox(height: 32),
          _buildSectionHeader("SYSTEM PROMPT"),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: _inputDecoration("Instructions", Icons.terminal_outlined),
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              "EchoScript Enterprise v$_appVersion",
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppTheme.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
    );
  }
}
