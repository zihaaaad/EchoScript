import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/models/app_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _promptController = TextEditingController();
  bool _isObscured = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.read(key: 'gemini_api_key');
    if (key != null && mounted) {
      _apiKeyController.text = key;
    }

    final isar = ref.read(isarProvider);
    final settings = await isar.appSettings.get(0);
    if (settings != null && mounted) {
      _promptController.text = settings.systemPrompt;
    }
  }

  Future<void> _saveApiKey(String key) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'gemini_api_key', value: key);
  }

  Future<void> _updateSettings(void Function(AppSettings) updateBlock) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final settings = await isar.appSettings.get(0) ?? AppSettings();
      updateBlock(settings);
      await isar.appSettings.put(settings);
    });
  }

  Future<void> _testConnection(AppSettings settings) async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API Key first')),
      );
      return;
    }

    setState(() => _isTesting = true);
    
    final transcriptionService = ref.read(transcriptionServiceProvider);
    final success = await transcriptionService.testApiKey(
      _apiKeyController.text, 
      settings.geminiModel,
    );

    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connection Successful!' : 'Connection Failed. Check your key and model.'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<AppSettings?>(
        stream: ref.watch(isarProvider).appSettings.watchObject(0, fireImmediately: true),
        builder: (context, snapshot) {
          final settings = snapshot.data ?? AppSettings();

          return ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSectionTitle('AI Configuration'),
              const SizedBox(height: 16),
              _buildApiKeyField(settings),
              const SizedBox(height: 16),
              _buildModelSelector(settings),
              const SizedBox(height: 16),
              _buildSystemPromptField(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Audio & Recording'),
              const SizedBox(height: 16),
              _buildAudioGainSlider(settings),
              const SizedBox(height: 16),
              _buildChunkDurationSelector(settings),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Performance'),
              const SizedBox(height: 16),
              _buildConcurrencySlider(settings),
            ],
          );
        },
      ),
    );

  Widget _buildSectionTitle(String title) => Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        letterSpacing: 1,
      ),
    );

  Widget _buildApiKeyField(AppSettings settings) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gemini API Key',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_isTesting) 
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else 
                TextButton(
                  onPressed: () => _testConnection(settings),
                  child: Text(
                    'Test Connection',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _isObscured,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter API Key',
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              ),
            ),
            onChanged: _saveApiKey,
          ),
        ],
      ),
    );

  Widget _buildModelSelector(AppSettings settings) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Version',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings.geminiModel,
            dropdownColor: AppTheme.surface,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash (Fast)')),
              DropdownMenuItem(value: 'gemini-1.5-pro', child: Text('Gemini 1.5 Pro (Accurate)')),
              DropdownMenuItem(value: 'gemini-2.5-flash', child: Text('Gemini 2.5 Flash (Latest)')),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateSettings((s) => s.geminiModel = value);
              }
            },
          ),
        ],
      ),
    );

  Widget _buildSystemPromptField() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Prompt',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 3,
            style: GoogleFonts.inter(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter system prompt...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => _updateSettings((s) => s.systemPrompt = value),
          ),
        ],
      ),
    );

  Widget _buildAudioGainSlider(AppSettings settings) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Software Audio Gain',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${settings.audioGainDb > 0 ? '+' : ''}${settings.audioGainDb.toStringAsFixed(1)} dB',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: settings.audioGainDb,
            min: -12.0,
            max: 24.0,
            divisions: 36,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.background,
            onChanged: (value) => _updateSettings((s) => s.audioGainDb = value),
          ),
        ],
      ),
    );

  Widget _buildChunkDurationSelector(AppSettings settings) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chunk Duration',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${settings.chunkDurationMinutes} min',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: settings.chunkDurationMinutes.toDouble(),
            min: 5.0,
            max: 60.0,
            divisions: 11, // 5, 10, 15...
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.background,
            onChanged: (value) => _updateSettings((s) => s.chunkDurationMinutes = value.toInt()),
          ),
        ],
      ),
    );

  Widget _buildConcurrencySlider(AppSettings settings) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Concurrent Transcriptions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${settings.aiConcurrencyLimit}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: settings.aiConcurrencyLimit.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.background,
            onChanged: (value) => _updateSettings((s) => s.aiConcurrencyLimit = value.toInt()),
          ),
        ],
      ),
    );
}
