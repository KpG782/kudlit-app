import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/core/audio/tts_service.dart';
import 'output_actions.dart';

class FilledOutput extends ConsumerWidget {
  const FilledOutput({
    super.key,
    required this.baybayin,
    required this.latin,
    required this.copyLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
  });

  final String baybayin;
  final String latin;
  final String copyLabel;
  final String shareLabel;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 340;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Text(
                baybayin,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Baybayin Simple TAWBID',
                  fontSize: narrow ? 42 : 54,
                  color: cs.onSurface,
                  letterSpacing: narrow ? 5 : 8,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(height: narrow ? 12 : 16),
            Container(width: 40, height: 1.5, color: cs.outline),
            SizedBox(height: narrow ? 10 : 14),
            Text(
              latin,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: narrow ? 17 : 20,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withAlpha(205),
              ),
            ),
            if (latin.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              _ListenButton(text: latin),
            ],
            SizedBox(height: narrow ? 18 : 24),
            OutputActions(
              copyLabel: copyLabel,
              shareLabel: shareLabel,
              onCopy: onCopy,
              onShare: onShare,
            ),
          ],
        );
      },
    );
  }
}

class _ListenButton extends ConsumerWidget {
  const _ListenButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Listen to pronunciation',
      child: TextButton.icon(
        onPressed: () => ref.read(ttsServiceProvider).speak(text),
        icon: const Icon(Icons.volume_up_rounded, size: 18),
        label: const Text('Listen'),
      ),
    );
  }
}
