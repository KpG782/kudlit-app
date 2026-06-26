import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/scan_result.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scan_history_provider.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ScanHistoryHeader(),
            const Expanded(child: _ScanHistoryList()),
          ],
        ),
      ),
    );
  }
}

class _ScanHistoryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            color: cs.onSurface,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Scanner History',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Recognized glyphs and saved readings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withAlpha(185),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanHistoryList extends ConsumerWidget {
  const _ScanHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ScanResult>> historyAsync = ref.watch(
      scanHistoryNotifierProvider,
    );

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => _ErrorState(
        onRetry: () => ref.invalidate(scanHistoryNotifierProvider),
      ),
      data: (List<ScanResult> results) {
        if (results.isEmpty) return const _EmptyState();
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            14,
            8,
            14,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int i) =>
              _ScanResultCard(result: results[i]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.document_scanner_outlined,
                  size: 44,
                  color: cs.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'No scans yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan Baybayin and your saved readings will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withAlpha(185),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            decoration: BoxDecoration(
              color: cs.errorContainer.withAlpha(90),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.error.withAlpha(90)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.cloud_off_rounded, size: 36, color: cs.error),
                const SizedBox(height: 12),
                Text(
                  "We couldn't load your scan history.\nCheck your connection "
                  'and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onErrorContainer,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.result});

  final ScanResult result;

  String _formattedDate(DateTime dt) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String word = result.tokens.join('');
    final String baybayin = baybayifyWord(word);
    final bool hasTranslation = result.translation.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (baybayin.isNotEmpty)
                      Text(
                        baybayin,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Baybayin Simple TAWBID',
                          fontSize: 21,
                          color: cs.onSurface,
                          letterSpacing: 3.5,
                          height: 1.25,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      word.isEmpty ? result.tokens.join(' · ') : word,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: _formattedDate(result.timestamp),
                cs: cs,
              ),
            ],
          ),
          if (hasTranslation) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.translation,
                style: TextStyle(
                  fontSize: 12.5,
                  color: cs.onSurface.withAlpha(200),
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          _TokenRow(tokens: result.tokens, cs: cs),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.cs});

  final IconData icon;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(180)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(185),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.tokens, required this.cs});

  final List<String> tokens;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tokens
          .map(
            (String t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withAlpha(190),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
