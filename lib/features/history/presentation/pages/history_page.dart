import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/modern_widgets.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/export_service.dart';
import '../../domain/models/audio_chunk.dart';
import '../../../recording/domain/repositories/transcription_repositories.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expandedChunkIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<AudioChunk>> _groupChunks(List<AudioChunk> chunks) {
    final groups = <String, List<AudioChunk>>{};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    for (final chunk in chunks) {
      final chunkDateStr = DateFormat('yyyy-MM-dd').format(chunk.createdAt);
      String groupKey;
      if (chunkDateStr == todayStr) {
        groupKey = 'Today';
      } else if (chunkDateStr == yesterdayStr) {
        groupKey = 'Yesterday';
      } else {
        groupKey = DateFormat('MMMM d, yyyy').format(chunk.createdAt);
      }

      groups.putIfAbsent(groupKey, () => []).add(chunk);
    }
    return groups;
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(transcriptionRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vault',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey),
                    tooltip: 'Clear All',
                    onPressed: () => _confirmClearAll(context, repo),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search transcripts...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Transcripts Stream
              Expanded(
                child: StreamBuilder<List<AudioChunk>>(
                  stream: repo.watchAllChunks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allChunks = snapshot.data ?? [];
                    final filteredChunks = allChunks.where((c) {
                      if (_searchQuery.isEmpty) return true;
                      final query = _searchQuery.toLowerCase();
                      final textMatch = c.transcript?.toLowerCase().contains(query) ?? false;
                      final dateMatch = DateFormat('MMMM d, yyyy')
                          .format(c.createdAt)
                          .toLowerCase()
                          .contains(query);
                      return textMatch || dateMatch;
                    }).toList();

                    if (filteredChunks.isEmpty) {
                      return _buildEmptyState();
                    }

                    final grouped = _groupChunks(filteredChunks);

                    return ListView.builder(
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final dateHeader = grouped.keys.elementAt(index);
                        final dateChunks = grouped[dateHeader]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
                              child: Text(
                                dateHeader,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ...dateChunks.map((chunk) => _buildChunkCard(chunk, repo)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 72, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No search matches' : 'Vault is empty',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try editing your keyword query.'
                : 'Completed recordings will appear here.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChunkCard(AudioChunk chunk, TranscriptionRepository repo) {
    final isExpanded = _expandedChunkIds.contains(chunk.id);
    final timeStr = DateFormat('jm').format(chunk.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Info and state)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedChunkIds.remove(chunk.id);
                  } else {
                    _expandedChunkIds.add(chunk.id);
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.audiotrack_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDuration(chunk.durationSeconds)} • ${chunk.wordCount} words',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusChip(status: chunk.status),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transcript text (Collapsible)
            if (isExpanded) ...[
              const Divider(height: 24, thickness: 0.5, color: Colors.white10),
              SelectableText(
                chunk.transcript ?? 'No transcript text available.',
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white),
              ),
              const SizedBox(height: 16),
              
              // Bottom Action Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Copy & Share
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy',
                        onTap: () {
                          if (chunk.transcript != null) {
                            Clipboard.setData(ClipboardData(text: chunk.transcript!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 2)),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Text',
                        onTap: () => ExportService.shareAsTxt(chunk),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'PDF',
                        onTap: () => ExportService.shareAsPdf(chunk),
                      ),
                    ],
                  ),
                  // Right: Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmDeleteChunk(context, repo, chunk.id),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChunk(BuildContext context, TranscriptionRepository repo, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transcript?'),
        content: const Text('This will delete this transcript permanently from the device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await repo.deleteChunk(id);
              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, TranscriptionRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Vault Data?'),
        content: const Text('Are you sure you want to permanently delete all transcripts from your vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await repo.clearAllChunks();
              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
